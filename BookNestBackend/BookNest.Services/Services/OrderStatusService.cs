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
    public class OrderStatusService : BaseCRUDService<OrderStatusResponse, OrderStatusSearchObject, OrderStatus, OrderStatusInsertRequest, OrderStatusUpdateRequest>, IOrderStatusService
    {
        private readonly BookNestDbContext _dbContext;

        public OrderStatusService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<OrderStatus> ApplyFilter(IQueryable<OrderStatus> query, OrderStatusSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(o => o.Name != null && o.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
