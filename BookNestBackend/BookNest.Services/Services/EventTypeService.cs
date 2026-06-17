using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;

namespace BookNest.Services.Services
{
    public class EventTypeService : BaseCRUDService<EventTypeResponse, EventTypeSearchObject, EventType, EventTypeInsertRequest, EventTypeUpdateRequest>, IEventTypeService
    {
        private readonly BookNestDbContext _dbContext;

        public EventTypeService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<EventType> ApplyFilter(IQueryable<EventType> query, EventTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(e => e.Name != null && e.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
