using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class OrderStatusProfile : Profile
    {
        public OrderStatusProfile()
        {
            CreateMap<OrderStatus, OrderStatusResponse>();
            CreateMap<OrderStatusInsertRequest, OrderStatus>();
            CreateMap<OrderStatusUpdateRequest, OrderStatus>();
        }
    }
}
