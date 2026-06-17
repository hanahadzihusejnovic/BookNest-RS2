using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class PaymentMethodProfile : Profile
    {
        public PaymentMethodProfile()
        {
            CreateMap<PaymentMethod, PaymentMethodResponse>();
            CreateMap<PaymentMethodInsertRequest, PaymentMethod>();
            CreateMap<PaymentMethodUpdateRequest, PaymentMethod>();
        }
    }
}
