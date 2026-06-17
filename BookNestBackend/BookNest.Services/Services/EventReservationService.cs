using AutoMapper;
using BookNest.Model.Constants;
using Microsoft.Extensions.Logging;
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
        private readonly ILogger<EventReservationService> _logger;

        public EventReservationService(BookNestDbContext dbContext, IMapper mapper,
            IRabbitMqPublisher publisher, ILogger<EventReservationService> logger) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
            _logger = logger;
            Stripe.StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
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

            if (search.ReservationStatusId.HasValue)
            {
                query = query.Where(r => r.ReservationStatusId == search.ReservationStatusId.Value);
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
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .AsQueryable();

            query = ApplyFilter(query, search);

            query = query.OrderByDescending(r => r.ReservationDate).ThenByDescending(r => r.Id);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync(cancellationToken);
            }

            if (search.RetrieveAll)
            {
                query = query.Take(500);
            }
            else
            {
                int skip = (search.Page ?? 0) * (search.PageSize ?? 20);
                int take = search.PageSize ?? 20;
                query = query.Skip(skip).Take(take);
            }

            var list = await query.ToListAsync(cancellationToken);

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
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
            {
                throw new NotFoundException("Reservation not found.");
            }

            return _mapper.Map<EventReservationResponse>(reservation);
        }

        public override Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            throw new BusinessException("Reservations cannot be deleted. Change the status to Cancelled instead.");
        }

        public async Task<EventReservationResponse> CreateReservationAsync(int userId, EventReservationInsertRequest request, CancellationToken cancellationToken = default)
        {
            var paymentMethodExists = await _dbContext.PaymentMethods
                .AnyAsync(pm => pm.Id == request.PaymentMethodId, cancellationToken);
            if (!paymentMethodExists)
                throw new BusinessException("Invalid payment method.");

            var user = await _dbContext.Users.FindAsync(new object[] { userId }, cancellationToken);
            if (user == null)
                throw new NotFoundException("User not found.");

            var eventEntity = await _dbContext.Events.FindAsync(new object[] { request.EventId }, cancellationToken);
            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            if (!eventEntity.IsActive)
                throw new BusinessException("Event is not active.");

            if (eventEntity.EventTypeId == EventTypes.Online && eventEntity.TicketPrice > 0 && request.PaymentMethodId != PaymentMethods.Card)
                throw new BusinessException("Cash upon arrival is not available for online events. Please use card payment.");

            var availableSeats = eventEntity.Capacity - eventEntity.ReservedSeats;
            if (availableSeats < request.Quantity)
                throw new BusinessException($"Not enough available seats. Only {availableSeats} seats available.");

            var existingReservation = await _dbContext.EventReservations
                .FirstOrDefaultAsync(r => r.UserId == userId
                                          && r.EventId == request.EventId
                                          && r.ReservationStatusId != ReservationStatuses.Cancelled, cancellationToken);

            if (existingReservation != null)
                throw new BusinessException("You already have a reservation for this event.");

            var eventDateTime = eventEntity.EventDateTime;
            if (eventDateTime < DateTime.UtcNow)
                throw new BusinessException("Cannot reserve seats for past events.");

            decimal totalPrice = eventEntity.TicketPrice * request.Quantity;

            bool isSuccessful;
            string? transactionId;

            if (request.PaymentMethodId == PaymentMethods.Card)
            {
                if (string.IsNullOrEmpty(request.TransactionId))
                    throw new BusinessException("PaymentIntentId is required for card payments.");

                var stripeService = new Stripe.PaymentIntentService();
                var intent = await stripeService.GetAsync(request.TransactionId, cancellationToken: cancellationToken);

                if (intent.Status != "requires_capture")
                    throw new BusinessException($"Payment not authorized. Stripe status: {intent.Status}");

                if (intent.Amount != (long)(totalPrice * 100))
                    throw new BusinessException("Payment amount does not match reservation total.");

                if (intent.Currency != "bam")
                    throw new BusinessException("Invalid payment currency.");

                var alreadyUsed = await _dbContext.Payments
                    .AnyAsync(p => p.TransactionId == intent.Id, cancellationToken);
                if (alreadyUsed)
                    throw new BusinessException("This payment has already been used.");

                if (intent.Metadata.TryGetValue("userId", out var metaUserId) && metaUserId != userId.ToString())
                    throw new BusinessException("Payment does not belong to this user.");

                isSuccessful = true;
                transactionId = intent.Id;
            }
            else
            {
                isSuccessful = true;
                transactionId = $"COA-{Guid.NewGuid()}";
            }

            EventReservation reservation;
            using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                reservation = new EventReservation
                {
                    UserId = userId,
                    EventId = request.EventId,
                    Quantity = request.Quantity,
                    TotalPrice = totalPrice,
                    EventDateTime = eventDateTime,
                    ReservationDate = DateTime.UtcNow,
                    ReservationStatusId = ReservationStatuses.Pending,
                    TicketQRCodeLink = GenerateQRCodeLink()
                };

                _dbContext.EventReservations.Add(reservation);
                await _dbContext.SaveChangesAsync(cancellationToken);

                var payment = new Payment
                {
                    UserId = userId,
                    PaymentMethodId = request.PaymentMethodId,
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
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }

            try
            {
                var adminUserIds = await GetAdminUserIdsAsync(cancellationToken);
                foreach (var adminId in adminUserIds)
                {
                    await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                    {
                        UserId = adminId,
                        EventId = request.EventId,
                        Title = "New reservation",
                        Message = $"User {user.Username} reserved {request.Quantity} ticket(s) for '{eventEntity.Name}' (reservation #{reservation.Id}).",
                        NotificationType = "NewReservation",
                        SendAt = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish new-reservation notification for reservation {ReservationId}", reservation.Id);
            }

            return await GetByIdAsync(reservation.Id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve created reservation.");
        }

        public async Task<List<EventReservationResponse>> GetUserReservationsAsync(int userId, CancellationToken cancellationToken = default)
        {
            var reservations = await _dbContext.EventReservations
                .Include(r => r.User)
                .Include(r => r.Event)
                    .ThenInclude(e => e.City)
                .Include(r => r.Event)
                    .ThenInclude(e => e.Country)
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                    .ThenInclude(p => p.PaymentMethod)
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
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .Where(r => r.EventId == eventId)
                .OrderByDescending(r => r.ReservationDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<EventReservationResponse>>(reservations);
        }

        private async Task<List<int>> GetAdminUserIdsAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.UserRoles
                .Where(ur => ur.Role.Name == Roles.Admin)
                .Select(ur => ur.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);
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

        private static readonly Dictionary<int, List<int>> _allowedReservationTransitions = new()
        {
            { ReservationStatuses.Pending,   new List<int> { ReservationStatuses.Confirmed, ReservationStatuses.Cancelled } },
            { ReservationStatuses.Confirmed, new List<int> { ReservationStatuses.Cancelled } },
            { ReservationStatuses.Cancelled, new List<int>() },
        };

        public override async Task<EventReservationResponse?> UpdateAsync(int id, EventReservationUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .Include(r => r.ReservationStatus)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            if (!_allowedReservationTransitions.TryGetValue(reservation.ReservationStatusId, out var allowed) || !allowed.Contains(request.ReservationStatusId))
                throw new BusinessException($"Cannot transition reservation from '{reservation.ReservationStatus?.Name}' to status ID {request.ReservationStatusId}.");

            if (request.ReservationStatusId == ReservationStatuses.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling a reservation.");

            if (request.ReservationStatusId == ReservationStatuses.Cancelled)
                reservation.Event.ReservedSeats = Math.Max(0, reservation.Event.ReservedSeats - reservation.Quantity);

            reservation.ReservationStatusId = request.ReservationStatusId;
            reservation.StatusChangedAt = DateTime.UtcNow;
            reservation.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.ReservationStatusId switch
            {
                ReservationStatuses.Confirmed => ("Reservation confirmed", $"Your reservation for '{reservation.Event.Name}' has been confirmed."),
                ReservationStatuses.Cancelled => ("Reservation cancelled", $"Your reservation for '{reservation.Event.Name}' has been cancelled. Reason: {request.CancellationReason}"),
                _ => ("Reservation updated", $"Your reservation for '{reservation.Event.Name}' has been updated.")
            };

            try
            {
                await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                {
                    UserId = reservation.UserId,
                    EventId = reservation.EventId,
                    Title = title,
                    Message = message,
                    NotificationType = "ReservationStatusChanged",
                    SendAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish notification for reservation {ReservationId}", reservation.Id);
            }

            return await GetByIdAsync(id, cancellationToken);
        }

        private static string GenerateQRCodeLink() => Guid.NewGuid().ToString();

        private static string BuildCancellationMessage(string eventName, string? reason, bool wasPending, bool isPaidByCard)
        {
            if (isPaidByCard)
            {
                return wasPending
                    ? $"Your reservation for '{eventName}' has been cancelled. Reason: {reason}. No charge was made to your card."
                    : $"Your reservation for '{eventName}' has been cancelled. Reason: {reason}. Your card payment requires a manual refund — please contact support.";
            }

            return $"Your reservation for '{eventName}' has been cancelled. Reason: {reason}";
        }

        public async Task<TicketValidationResponse> ValidateTicketAsync(string token, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .Include(r => r.User)
                .Include(r => r.ReservationStatus)
                .FirstOrDefaultAsync(r => r.TicketQRCodeLink == token, cancellationToken);

            if (reservation == null)
                return new TicketValidationResponse { IsValid = false, Message = "Invalid ticket token." };

            if (reservation.ReservationStatusId == ReservationStatuses.Cancelled)
                return new TicketValidationResponse
                {
                    IsValid = false,
                    Message = "This ticket has been cancelled.",
                    ReservationId = reservation.Id,
                    EventName = reservation.Event.Name,
                    ReservationStatus = reservation.ReservationStatus?.Name ?? "Cancelled",
                    UserFullName = $"{reservation.User.FirstName} {reservation.User.LastName}"
                };

            if (!reservation.Event.IsActive)
                return new TicketValidationResponse
                {
                    IsValid = false,
                    Message = "This event has been cancelled or deactivated.",
                    ReservationId = reservation.Id,
                    EventName = reservation.Event.Name,
                    ReservationStatus = reservation.ReservationStatus?.Name ?? string.Empty,
                    UserFullName = $"{reservation.User.FirstName} {reservation.User.LastName}"
                };

            return new TicketValidationResponse
            {
                IsValid = true,
                Message = "Valid ticket.",
                ReservationId = reservation.Id,
                EventName = reservation.Event.Name,
                EventDate = reservation.Event.EventDate,
                EventTime = reservation.Event.EventTime,
                Quantity = reservation.Quantity,
                ReservationStatus = reservation.ReservationStatus?.Name ?? string.Empty,
                UserFullName = $"{reservation.User.FirstName} {reservation.User.LastName}"
            };
        }

        public async Task<EventReservationResponse> CancelUserReservationAsync(int id, int userId, string cancellationReason, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null || reservation.UserId != userId)
                throw new NotFoundException("Reservation not found.");

            if (!_allowedReservationTransitions.TryGetValue(reservation.ReservationStatusId, out var allowed)
                || !allowed.Contains(ReservationStatuses.Cancelled))
                throw new BusinessException($"Cannot cancel a reservation with status '{reservation.ReservationStatus?.Name}'.");

            if (string.IsNullOrWhiteSpace(cancellationReason))
                throw new BusinessException("Cancellation reason is required.");

            bool wasPending = reservation.ReservationStatusId == ReservationStatuses.Pending;
            bool isPaidByCard = reservation.Payment?.PaymentMethodId == PaymentMethods.Card;
            bool hasTransactionId = !string.IsNullOrEmpty(reservation.Payment?.TransactionId);

            if (wasPending && isPaidByCard && hasTransactionId)
            {
                var cancelIntentService = new Stripe.PaymentIntentService();
                await cancelIntentService.CancelAsync(reservation.Payment!.TransactionId, cancellationToken: cancellationToken);
            }

            reservation.Event.ReservedSeats = Math.Max(0, reservation.Event.ReservedSeats - reservation.Quantity);
            reservation.ReservationStatusId = ReservationStatuses.Cancelled;
            reservation.StatusChangedAt = DateTime.UtcNow;
            reservation.StatusChangedByUserId = userId;
            reservation.CancellationReason = cancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            try
            {
                var adminUserIds = await GetAdminUserIdsAsync(cancellationToken);
                foreach (var adminId in adminUserIds)
                {
                    await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                    {
                        UserId = adminId,
                        EventId = reservation.EventId,
                        Title = "Reservation cancelled by user",
                        Message = $"User {reservation.User.Username} cancelled reservation #{reservation.Id} for '{reservation.Event.Name}'. Reason: {cancellationReason}",
                        NotificationType = "ReservationCancelledByUser",
                        SendAt = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish reservation-cancelled-by-user notification for reservation {ReservationId}", reservation.Id);
            }

            return await GetByIdAsync(id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve cancelled reservation.");
        }

        public async Task<EventReservationResponse?> UpdateStatusAsync(int id, EventReservationUpdateRequest request, int changedByUserId, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .Include(r => r.ReservationStatus)
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            if (!_allowedReservationTransitions.TryGetValue(reservation.ReservationStatusId, out var allowed) || !allowed.Contains(request.ReservationStatusId))
                throw new BusinessException($"Cannot transition reservation from '{reservation.ReservationStatus?.Name}' to status ID {request.ReservationStatusId}.");

            if (request.ReservationStatusId == ReservationStatuses.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling a reservation.");

            bool wasPending = reservation.ReservationStatusId == ReservationStatuses.Pending;
            bool isPaidByCard = reservation.Payment?.PaymentMethodId == PaymentMethods.Card;
            bool hasTransactionId = !string.IsNullOrEmpty(reservation.Payment?.TransactionId);

            if (request.ReservationStatusId == ReservationStatuses.Confirmed && wasPending && isPaidByCard && hasTransactionId)
            {
                var captureService = new Stripe.PaymentIntentService();
                await captureService.CaptureAsync(reservation.Payment!.TransactionId, cancellationToken: cancellationToken);
            }

            if (request.ReservationStatusId == ReservationStatuses.Cancelled)
            {
                reservation.Event.ReservedSeats = Math.Max(0, reservation.Event.ReservedSeats - reservation.Quantity);

                if (wasPending && isPaidByCard && hasTransactionId)
                {
                    var cancelIntentService = new Stripe.PaymentIntentService();
                    await cancelIntentService.CancelAsync(reservation.Payment!.TransactionId, cancellationToken: cancellationToken);
                }
            }

            reservation.ReservationStatusId = request.ReservationStatusId;
            reservation.StatusChangedAt = DateTime.UtcNow;
            reservation.StatusChangedByUserId = changedByUserId;
            reservation.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.ReservationStatusId switch
            {
                ReservationStatuses.Confirmed => ("Reservation confirmed", $"Your reservation for '{reservation.Event.Name}' has been confirmed."),
                ReservationStatuses.Cancelled => ("Reservation cancelled", BuildCancellationMessage(reservation.Event.Name, request.CancellationReason, wasPending, isPaidByCard)),
                _ => ("Reservation updated", $"Your reservation for '{reservation.Event.Name}' has been updated.")
            };

            try
            {
                await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                {
                    UserId = reservation.UserId,
                    EventId = reservation.EventId,
                    Title = title,
                    Message = message,
                    NotificationType = "ReservationStatusChanged",
                    SendAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish notification for reservation {ReservationId}", reservation.Id);
            }

            return await GetByIdAsync(id, cancellationToken);
        }

        public async Task SendReminderAsync(int reservationId, CancellationToken cancellationToken = default)
        {
            var reservation = await _dbContext.EventReservations
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == reservationId, cancellationToken);

            if (reservation == null)
                throw new NotFoundException("Reservation not found.");

            if (reservation.ReservationStatusId == ReservationStatuses.Cancelled)
                throw new BusinessException("Cannot send a reminder for a cancelled reservation.");

            if (!reservation.Event.IsActive)
                throw new BusinessException("Cannot send a reminder for an inactive event.");

            var eventDateTime = reservation.Event.EventDateTime;
            if (eventDateTime < DateTime.UtcNow)
                throw new BusinessException("Cannot send a reminder for an event that has already passed.");

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

        public async Task<PaymentIntentResponse> CreateEventPaymentIntentAsync(int userId, EventPaymentIntentRequest request, CancellationToken cancellationToken = default)
        {
            var ev = await _dbContext.Events
                .FirstOrDefaultAsync(e => e.Id == request.EventId, cancellationToken);

            if (ev == null)
                throw new NotFoundException("Event not found.");

            if (!ev.IsActive)
                throw new BusinessException("Event is not active.");

            if (ev.EventDateTime <= DateTime.UtcNow)
                throw new BusinessException("Event has already passed.");

            var availableSeats = ev.Capacity - ev.ReservedSeats;
            if (request.Quantity > availableSeats)
                throw new BusinessException($"Not enough available seats. Available: {availableSeats}.");

            decimal total = ev.TicketPrice * request.Quantity;

            var options = new Stripe.PaymentIntentCreateOptions
            {
                Amount = (long)(total * 100),
                Currency = "bam",
                PaymentMethodTypes = new List<string> { "card" },
                CaptureMethod = "manual",
                Metadata = new Dictionary<string, string>
                {
                    { "userId", userId.ToString() },
                    { "eventId", ev.Id.ToString() },
                    { "quantity", request.Quantity.ToString() }
                }
            };

            var service = new Stripe.PaymentIntentService();
            var intent = await service.CreateAsync(options);

            return new PaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            };
        }
    }
}
