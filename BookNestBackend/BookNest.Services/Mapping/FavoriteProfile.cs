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
    public class FavoriteProfile : Profile
    {
        public FavoriteProfile()
        {
            CreateMap<Favorite, FavoriteResponse>()
                .ForMember(dest => dest.BookTitle, opt => opt.MapFrom(src => src.Book.Title))
                .ForMember(dest => dest.BookAuthor, opt => opt.MapFrom(src =>
                    src.Book.Author != null
                        ? src.Book.Author.FirstName + " " + src.Book.Author.LastName
                        : "Unknown"))
                .ForMember(dest => dest.BookImageUrl, opt => opt.MapFrom(src => src.Book.CoverImageUrl ?? string.Empty))
                .ForMember(dest => dest.BookPrice, opt => opt.MapFrom(src => src.Book.Price));

            CreateMap<FavoriteInsertRequest, Favorite>();
        }
    }
}
