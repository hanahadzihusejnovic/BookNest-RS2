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
    public class EventService : BaseCRUDService<EventResponse, EventSearchObject,Event, EventInsertRequest, EventUpdateRequest>, IEventService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IRabbitMqPublisher _publisher;

        public EventService(BookNestDbContext dbContext, IMapper mapper,
            IRabbitMqPublisher publisher) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
        }

        protected override IQueryable<Event> ApplyFilter(IQueryable<Event> query, EventSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(e => 
                    e.Name != null && e.Name.ToLower().Contains(lower) ||
                    e.EventCategory != null && e.EventCategory.Name.ToLower().Contains(lower) ||
                    e.Organizer != null && e.Organizer.FirstName.ToLower().Contains(lower) ||
                    e.City != null && e.City.Name.ToLower().Contains(lower) ||
                    e.Country != null && e.Country.Name.ToLower().Contains(lower)
                    );
            }

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(e => e.Name != null &&
                                         e.Name.ToLower().Contains(search.Name.ToLower()));
            }

            if (search.EventCategoryId.HasValue)
            {
                query = query.Where(e => e.EventCategoryId == search.EventCategoryId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search.CategoryName))
            {
                query = query.Where(e => e.EventCategory != null &&
                                         e.EventCategory.Name.ToLower().Contains(search.CategoryName.ToLower()));
            }

            if (search.OrganizerId.HasValue)
            {
                query = query.Where(e => e.OrganizerId == search.OrganizerId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search.OrganizerName))
            {
                query = query.Where(e => e.Organizer != null &&
                                         e.Organizer.FirstName.ToLower().Contains(search.OrganizerName.ToLower()));
            }

            if (search.EventType.HasValue)
            {
                query = query.Where(e => e.EventType == search.EventType.Value);
            }

            if (!string.IsNullOrWhiteSpace(search.City))
            {
                query = query.Where(e => e.City != null &&
                                         e.City.Name.ToLower().Contains(search.City.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.Country))
            {
                query = query.Where(e => e.Country != null &&
                                         e.Country.Name.ToLower().Contains(search.Country.ToLower()));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(e => e.IsActive == search.IsActive.Value);
            }

            if (search.DateFrom.HasValue)
            {
                query = query.Where(e => e.EventDate >= search.DateFrom.Value);
            }

            if (search.DateTo.HasValue)
            {
                query = query.Where(e => e.EventDate <= search.DateTo.Value);
            }

            return query;
        }

        public override async Task<PagedResult<EventResponse>> GetAsync(EventSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Events
                         .Include(e => e.EventCategory)
                         .Include(e => e.Organizer)
                         .Include(e => e.City)
                         .Include(e => e.Country)
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

            var list = await query.ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<EventResponse>>(list);

            return new PagedResult<EventResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var eventEntity = await _dbContext.Events
                                   .Include(e => e.EventCategory)
                                   .Include(e => e.Organizer)
                                   .Include(e => e.City)
                                   .Include(e => e.Country)
                                   .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

            if (eventEntity == null)
            {
                throw new NotFoundException("Event not found.");
            }

            return _mapper.Map<EventResponse>(eventEntity);

        }

        public override async Task<EventResponse> CreateAsync(EventInsertRequest request, CancellationToken cancellationToken = default)
        {
            var eventEntity = _mapper.Map<Event>(request);

            _dbContext.Events.Add(eventEntity);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(eventEntity.Id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve created event.");
        }

        public async Task<List<EventRecommendationResponse>> GetRecommendedEventsAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
        {
            var myEventIds = await _dbContext.EventReservations
                .Where(r => r.UserId == userId)
                .Select(r => r.EventId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var similarUserIds = await _dbContext.EventReservations
                .Where(r => r.UserId != userId && myEventIds.Contains(r.EventId))
                .Select(r => r.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var collaborativeEventIds = await _dbContext.EventReservations
                .Where(r => similarUserIds.Contains(r.UserId) && !myEventIds.Contains(r.EventId))
                .Select(r => r.EventId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var now = DateTime.UtcNow;

            var events = await _dbContext.Events
                .Include(e => e.EventCategory)
                .Include(e => e.Organizer)
                .Where(e => collaborativeEventIds.Contains(e.Id) &&
                            e.IsActive &&
                            e.EventDate > now)
                .ToListAsync(cancellationToken);

            var result = events.Select(e =>
            {
                var daysUntilEvent = (e.EventDate - now).TotalDays;
                var score = Math.Max(0, 1 - (daysUntilEvent / 365.0));

                return (ev: e, score, daysUntilEvent);
            })
            .OrderBy(x => x.daysUntilEvent)
            .Take(count)
            .Select(x => new EventRecommendationResponse
            {
                Event = _mapper.Map<EventResponse>(x.ev),
                Reason = $"Users with similar interests reserved this event" +
                         $", happening in {(int)x.daysUntilEvent} day(s)."
            })
            .ToList();

            return result;
        }

        public async Task<List<EventRecommendationResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
        {
            var myEventIds = await _dbContext.EventReservations
                .Where(r => r.UserId == userId)
                .Select(r => r.EventId)
                .Distinct()
                .ToListAsync(cancellationToken);

            if (!myEventIds.Any())
                return new List<EventRecommendationResponse>();

            var preferredCategories = await _dbContext.EventReservations
                .Where(r => r.UserId == userId)
                .Include(r => r.Event)
                    .ThenInclude(e => e.EventCategory)
                .Select(r => new { r.Event.EventCategoryId, r.Event.EventCategory.Name })
                .Distinct()
                .ToListAsync(cancellationToken);

            var preferredCategoryIds = preferredCategories.Select(c => c.EventCategoryId).ToList();
            var preferredCategoryNames = preferredCategories.Select(c => c.Name).ToList();

            var now = DateTime.UtcNow;

            IQueryable<Event> query = _dbContext.Events
                .Include(e => e.EventCategory)
                .Include(e => e.Organizer)
                .Where(e => e.IsActive &&
                            e.EventDate > now &&
                            !myEventIds.Contains(e.Id));

            if (preferredCategoryIds.Any())
            {
                query = query.Where(e => preferredCategoryIds.Contains(e.EventCategoryId));
            }

            var events = await query.ToListAsync(cancellationToken);

            var result = events.Select(e =>
            {
                var daysUntilEvent = (e.EventDate - now).TotalDays;

                return (ev: e, daysUntilEvent);
            })
            .OrderBy(x => x.daysUntilEvent)
            .Take(count)
            .Select(x => new EventRecommendationResponse
            {
                Event = _mapper.Map<EventResponse>(x.ev),
                Reason = $"Matches your interest in {string.Join(", ", preferredCategoryNames)}" +
                         $", happening in {(int)x.daysUntilEvent} day(s)."
            })
            .ToList();

            return result;
        }

        public override async Task<EventResponse?> UpdateAsync(int id, EventUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var eventEntity = await _dbContext.Events
                .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

            if (eventEntity == null)
                throw new NotFoundException("Event not found.");

            bool wasActive = eventEntity.IsActive;

            _mapper.Map(request, eventEntity);
            await _dbContext.SaveChangesAsync(cancellationToken);

            if (wasActive && !request.IsActive)
            {
                var affectedReservations = await _dbContext.EventReservations
                    .Where(r => r.EventId == id &&
                                r.ReservationStatus != ReservationStatus.Cancelled)
                    .ToListAsync(cancellationToken);

                foreach (var reservation in affectedReservations)
                {
                    await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                    {
                        UserId = reservation.UserId,
                        EventId = id,
                        Title = "Event cancelled",
                        Message = $"Unfortunately, the event '{eventEntity.Name}' has been cancelled.",
                        NotificationType = "EventCancelled",
                        SendAt = DateTime.UtcNow
                    });
                }
            }

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}
