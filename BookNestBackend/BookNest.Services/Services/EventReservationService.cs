using AutoMapper;
using BookNest.Model.Enums;
using BookNest.Model.Exceptions;
using BookNest.Model.Messages;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using BookNest.Services.MessageQueue;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class EventReservationService : BaseCRUDService<EventReservationResponse, EventReservationSearchObject, EventReservation, EventReservationInsertRequest, EventReservationUpdateRequest>, IEventReservationService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IRabbitMqPublisher _publisher;

        public EventReservationService(BookNestDbContext dbContext, IMapper mapper,
            IRabbitMqPublisher publisher) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
        }

        protected override IQueryable<EventReservation> ApplyFilter(IQueryable<EventReservation> query, EventReservationSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.EventId.HasValue)
            {
                query = query.Where(r => r.EventId == search.EventId.Value);
            }

            if (search.ReservationStatus.HasValue)
            {
                query = query.Where(r => r.ReservationStatus == search.ReservationStatus.Value);
            }

            if (search.ReservationDateFrom.HasValue)
            {
                query = query.Where(r => r.ReservationDate >= search.ReservationDateFrom.Value);
            }

            if (search.ReservationDateTo.HasValue)
            {
                query = query.Where(r => r.ReservationDate <= search.ReservationDateTo.Value);
            }

            return query;
        }

        public override async Task<PagedResult<EventReservationResponse>> GetAsync(EventReservationSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
                    .ThenInclude(e => e.City)
                .Include(r => r.Event)
                    .ThenInclude(e => e.Country)
                .Include(r => r.Payment)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync(cancellationToken);
            }

            if (!search.RetrieveAll)
            {
                int skip = (search.Page ?? 0) * (search.PageSize ?? 20);
                int take = search.PageSize ?? 20;

                query = query.Skip(skip).Take(take);
            }

            var list = await query
                .OrderByDescending(r => r.ReservationDate)
                .ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<EventReservationResponse>>(list);

            return new PagedResult<EventReservationResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<EventReservationResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
                    .ThenInclude(e => e.City)
                .Include(r => r.Event)
                    .ThenInclude(e => e.Country)
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
            {
                throw new NotFoundException("Reservation not found.");
            }

            return _mapper.Map<EventReservationResponse>(reservation);
        }

        public override async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Payment)
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
            {
                throw new NotFoundException("Reservation not found.");
            }

            if (reservation.Payment != null)
            {
                _dbContext.Payments.Remove(reservation.Payment);
            }

            var eventEntity = reservation.Event;
            if (eventEntity != null)
            {
                eventEntity.ReservedSeats -= reservation.Quantity;
            }

            _dbContext.EventReservations.Remove(reservation);

            await _dbContext.SaveChangesAsync(cancellationToken);

            return true;
        }

        public async Task<EventReservationResponse> CreateReservationAsync(int userId, EventReservationInsertRequest request, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users.FindAsync(new object[] { userId }, cancellationToken);
            if (user == null)
                throw new NotFoundException("User not found.");

            var eventEntity = await _dbContext.Events.FindAsync(new object[] { request.EventId }, cancellationToken);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (!eventEntity.IsActive)
                throw new BusinessException("Event is not active.");

            var availableSeats = eventEntity.Capacity - eventEntity.ReservedSeats;
            if (availableSeats < request.Quantity)
                throw new BusinessException($"Not enough available seats. Only {availableSeats} seats available.");

            var existingReservation = await _dbContext.EventReservations
                .FirstOrDefaultAsync(r => r.UserId == userId
                                          && r.EventId == request.EventId
                                          && r.ReservationStatus != ReservationStatus.Cancelled, cancellationToken);

            if (existingReservation != null)
                throw new BusinessException("You already have a reservation for this event.");

            var eventDateTime = eventEntity.EventDate.Date + eventEntity.EventTime;
            if (eventDateTime < DateTime.UtcNow)
                throw new BusinessException("Cannot reserve seats for past events.");

            decimal totalPrice = eventEntity.TicketPrice * request.Quantity;

            // Verificiraj plaćanje na serveru
            bool isSuccessful;
            string? transactionId;

            if (request.PaymentMethod == PaymentMethod.Card)
            {
                if (string.IsNullOrEmpty(request.TransactionId))
                    throw new BusinessException("PaymentIntentId is required for card payments.");

                Stripe.StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
                var stripeService = new Stripe.PaymentIntentService();
                var intent = await stripeService.GetAsync(request.TransactionId, cancellationToken: cancellationToken);

                if (intent.Status != "succeeded")
                    throw new BusinessException($"Payment not completed. Stripe status: {intent.Status}");

                isSuccessful = true;
                transactionId = intent.Id;
            }
            else
            {
                // Cash on Arrival — server evidentira kao uspješno
                isSuccessful = true;
                transactionId = $"COA-{Guid.NewGuid()}";
            }

            using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var reservation = new EventReservation
                {
                    UserId = userId,
                    EventId = request.EventId,
                    Quantity = request.Quantity,
                    TotalPrice = totalPrice,
                    EventDateTime = eventDateTime,
                    ReservationDate = DateTime.UtcNow,
                    ReservationStatus = ReservationStatus.Pending,
                    TicketQRCodeLink = GenerateQRCodeLink()
                };

                _dbContext.EventReservations.Add(reservation);
                await _dbContext.SaveChangesAsync(cancellationToken);

                var payment = new Payment
                {
                    UserId = userId,
                    PaymentMethod = request.PaymentMethod,
                    Amount = totalPrice,
                    EventReservationId = reservation.Id,
                    PaymentDate = DateTime.UtcNow,
                    IsSuccessful = isSuccessful,
                    TransactionId = transactionId
                };

                _dbContext.Payments.Add(payment);
                eventEntity.ReservedSeats += request.Quantity;

                await _dbContext.SaveChangesAsync(cancellationToken);

                await transaction.CommitAsync(cancellationToken);

                return await GetByIdAsync(reservation.Id, cancellationToken)
                       ?? throw new BusinessException("Failed to retrieve created reservation.");
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }

        public async Task<List<EventReservationResponse>> GetUserReservationsAsync(int userId, CancellationToken cancellationToken = default)
        {
            var reservations = await _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
                    .ThenInclude(e => e.City)
                .Include(r => r.Event)
                    .ThenInclude(e => e.Country)
                .Include(r => r.Payment)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.ReservationDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<EventReservationResponse>>(reservations);
        }

        public async Task<List<EventReservationResponse>> GetEventReservationsAsync(int eventId, CancellationToken cancellationToken = default)
        {
            var reservations = await _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
                    .ThenInclude(e => e.City)
                .Include(r => r.Event)
                    .ThenInclude(e => e.Country)
                .Include(r => r.Payment)
                .Where(r => r.EventId == eventId)
                .OrderByDescending(r => r.ReservationDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<EventReservationResponse>>(reservations);
        }

        public async Task<int> GetAvailableSeatsAsync(int eventId, CancellationToken cancellationToken = default)
        {
            var eventEntity = await _dbContext.Events.FindAsync(new object[] { eventId }, cancellationToken);
            if (eventEntity == null)
            {
                throw new NotFoundException("Event not found.");
            }

            return eventEntity.Capacity - eventEntity.ReservedSeats;
        }

        public override async Task<EventReservationResponse?> UpdateAsync(int id, EventReservationUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            reservation.ReservationStatus = request.ReservationStatus;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.ReservationStatus switch
            {
                ReservationStatus.Confirmed => ("Reservation confirmed", $"Your reservation for '{reservation.Event.Name}' has been confirmed."),
                ReservationStatus.Cancelled => ("Reservation cancelled", $"Your reservation for '{reservation.Event.Name}' has been cancelled."),
                ReservationStatus.Attended => ("Thank you for attending", $"We hope you enjoyed '{reservation.Event.Name}'!"),
                _ => ("Reservation updated", $"Your reservation for '{reservation.Event.Name}' has been updated.")
            };

            await _publisher.PublishAsync("notifications-queue", new NotificationMessage
            {
                UserId = reservation.UserId,
                EventId = reservation.EventId,
                Title = title,
                Message = message,
                NotificationType = "ReservationStatusChanged",
                SendAt = DateTime.UtcNow
            });

            return await GetByIdAsync(id, cancellationToken);
        }

        private string GenerateQRCodeLink()
        {
            return $"https://booknest.com/tickets/{Guid.NewGuid()}";
        }

        public async Task SendReminderAsync(int reservationId, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == reservationId, cancellationToken);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            await _publisher.PublishAsync("notifications-queue", new NotificationMessage
            {
                UserId = reservation.UserId,
                EventId = reservation.EventId,
                Title = "Event reminder",
                Message = $"Reminder: '{reservation.Event.Name}' is coming up on {reservation.Event.EventDate:dd.MM.yyyy} at {reservation.Event.EventTime:hh\\:mm}.",
                NotificationType = "EventReminder",
                SendAt = DateTime.UtcNow
            });
        }
    }
}
