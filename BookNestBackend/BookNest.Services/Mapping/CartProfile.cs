using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Mapping
{
    public class CartProfile : Profile
    {
        public CartProfile()
        {
            CreateMap<Cart, CartResponse>()
                .ForMember(dest => dest.CartItems, opt => opt.MapFrom(src => src.CartItems));

            CreateMap<CartItem, CartItemResponse>()
                .ForMember(dest => dest.BookTitle, opt => opt.MapFrom(src => src.Book.Title))
                .ForMember(dest => dest.BookImageUrl, opt => opt.MapFrom(src => src.Book.CoverImageUrl ?? string.Empty))
                .ForMember(dest => dest.Subtotal, opt => opt.MapFrom(src => src.Price * src.Quantity));

            CreateMap<CartInsertRequest, Cart>();
            CreateMap<CartUpdateRequest, Cart>();
        }
    }
}
