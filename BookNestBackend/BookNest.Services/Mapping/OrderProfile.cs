using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class OrderProfile : Profile
    {
        public OrderProfile()
        {
            CreateMap<Order, OrderResponse>()
                .ForMember(dest => dest.UserFullName, opt => opt.MapFrom(src => src.User.FirstName + " " + src.User.LastName))
                .ForMember(dest => dest.Shipping, opt => opt.MapFrom(src => src.Shipping))
                .ForMember(dest => dest.Payment, opt => opt.MapFrom(src => src.Payment))
                .ForMember(dest => dest.OrderItems, opt => opt.MapFrom(src => src.OrderItems));

            CreateMap<OrderItem, OrderItemResponse>()
                .ForMember(dest => dest.BookTitle, opt => opt.MapFrom(src => src.Book.Title))
                .ForMember(dest => dest.BookAuthorName, opt => opt.MapFrom(src => src.Book.Author.FirstName + " " + src.Book.Author.LastName))
                .ForMember(dest => dest.BookImageUrl, opt => opt.MapFrom(src => src.Book.CoverImageUrl))
                .ForMember(dest => dest.Subtotal, opt => opt.MapFrom(src => src.Quantity * src.Price));

            CreateMap<Shipping, ShippingResponse>()
                .ForMember(dest => dest.CityId, opt => opt.MapFrom(src => src.CityId))
                .ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.City != null ? src.City.Name : null))
                .ForMember(dest => dest.CountryId, opt => opt.MapFrom(src => src.CountryId))
                .ForMember(dest => dest.CountryName, opt => opt.MapFrom(src => src.Country != null ? src.Country.Name : null));

            CreateMap<Payment, PaymentResponse>();

            CreateMap<OrderInsertRequest, Order>();

            CreateMap<OrderUpdateRequest, Order>();

            CreateMap<ShippingInsertRequest, Shipping>();
        }
    }
}