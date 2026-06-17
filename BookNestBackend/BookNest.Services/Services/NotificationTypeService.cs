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
    public class NotificationTypeService : BaseCRUDService<NotificationTypeResponse, NotificationTypeSearchObject, NotificationType, NotificationTypeInsertRequest, NotificationTypeUpdateRequest>, INotificationTypeService
    {
        private readonly BookNestDbContext _dbContext;

        public NotificationTypeService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<NotificationType> ApplyFilter(IQueryable<NotificationType> query, NotificationTypeSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(n => n.Name != null && n.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
