using AutoMapper;
using BookNest.Model.Enums;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database.Entities;
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using BookNest.Services.MessageQueue;
using BookNest.Model.Messages;

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
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
            {
                return null;
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
                return false;
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
            {
                throw new Exception($"User with ID {userId} does not exist in database.");
            }

            var eventEntity = await _dbContext.Events.FindAsync(new object[] { request.EventId }, cancellationToken);
            if (eventEntity == null)
            {
                throw new Exception("Event not found.");
            }

            if (!eventEntity.IsActive)
            {
                throw new Exception("Event is not active.");
            }

            var availableSeats = eventEntity.Capacity - eventEntity.ReservedSeats;
            if (availableSeats < request.Quantity)
            {
                throw new Exception($"Not enough available seats. Only {availableSeats} seats available.");
            }

            var existingReservation = await _dbContext.EventReservations.FirstOrDefaultAsync(r => r.UserId == userId
                                                                                                  && r.EventId == request.EventId
                                                                                                  && r.ReservationStatus != ReservationStatus.Cancelled, cancellationToken);

            if (existingReservation != null)
                throw new Exception("You already have a reservation for this event.");

            var eventDateTime = eventEntity.EventDate.Date + eventEntity.EventTime;
            if (eventDateTime < DateTime.UtcNow)
            {
                throw new Exception("Cannot reserve seats for past events.");
            }

            decimal totalPrice = eventEntity.TicketPrice * request.Quantity;

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
                IsSuccessful = true,
                TransactionId = request.TransactionId
            };

            _dbContext.Payments.Add(payment);

            eventEntity.ReservedSeats += request.Quantity;

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(reservation.Id, cancellationToken)
                   ?? throw new Exception("Failed to retrieve created reservation.");
        }

        public async Task<List<EventReservationResponse>> GetUserReservationsAsync(int userId, CancellationToken cancellationToken = default)
        {
            var reservations = await _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
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
                throw new Exception("Event not found.");
            }

            return eventEntity.Capacity - eventEntity.ReservedSeats;
        }

        public override async Task<EventReservationResponse?> UpdateAsync(int id, EventReservationUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null) return null;

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
                throw new Exception("Reservation not found.");

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
