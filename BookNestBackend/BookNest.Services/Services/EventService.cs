using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BookNest.Services.MessageQueue;
using BookNest.Model.Messages;
using BookNest.Model.Enums;

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
                    e.City != null && e.City.ToLower().Contains(lower) ||
                    e.Country != null && e.Country.ToLower().Contains(lower)
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
                                         e.City.ToLower().Contains(search.City.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.Country))
            {
                query = query.Where(e => e.Country != null &&
                                         e.Country.ToLower().Contains(search.Country.ToLower()));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(e => e.IsActive == search.IsActive.Value);
            }

            return query;
        }

        public override async Task<PagedResult<EventResponse>> GetAsync(EventSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Events
                         .Include(e => e.EventCategory)
                         .Include(e => e.Organizer)
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
            var eventt = await _dbContext.Events
                               .Include(e => e.EventCategory)
                               .Include(e => e.Organizer)
                               .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

            if(eventt == null)
            {
                return null;
            }

            return _mapper.Map<EventResponse>(eventt);

        }

        public override async Task<EventResponse> CreateAsync(EventInsertRequest request, CancellationToken cancellationToken = default)
        {
            var eventEntity = _mapper.Map<Event>(request);

            _dbContext.Events.Add(eventEntity);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(eventEntity.Id, cancellationToken)
                   ?? throw new Exception("Failed to retrieve created event.");
        }

        public async Task<List<EventResponse>> GetRecommendedEventsAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
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

            var recommended = await _dbContext.Events
                .Include(e => e.EventCategory)
                .Include(e => e.Organizer)
                .Where(e => collaborativeEventIds.Contains(e.Id) &&
                            e.IsActive &&
                            e.EventDate > now)
                .OrderBy(e => e.EventDate)
                .Take(count)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<EventResponse>>(recommended);
        }

        public async Task<List<EventResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
        {
            var myEventIds = await _dbContext.EventReservations
                .Where(r => r.UserId == userId)
                .Select(r => r.EventId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var preferredCategoryIds = await _dbContext.EventReservations
                .Where(r => r.UserId == userId)
                .Include(r => r.Event)
                .Select(r => r.Event.EventCategoryId)
                .Distinct()
                .ToListAsync(cancellationToken);

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

            var recommended = await query
                .OrderBy(e => e.EventDate)
                .Take(count)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<EventResponse>>(recommended);
        }

        public override async Task<EventResponse?> UpdateAsync(int id, EventUpdateRequest request,
    CancellationToken cancellationToken = default)
        {
            var eventEntity = await _dbContext.Events
                .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

            if (eventEntity == null) return null;

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
