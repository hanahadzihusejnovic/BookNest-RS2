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
    public class PaymentMethodService : BaseCRUDService<PaymentMethodResponse, PaymentMethodSearchObject, PaymentMethod, PaymentMethodInsertRequest, PaymentMethodUpdateRequest>, IPaymentMethodService
    {
        private readonly BookNestDbContext _dbContext;

        public PaymentMethodService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<PaymentMethod> ApplyFilter(IQueryable<PaymentMethod> query, PaymentMethodSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(p => p.Name != null && p.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
