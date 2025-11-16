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
    public class BookProfile : Profile
    {
        public BookProfile() 
        {
            CreateMap<Book, BookResponse>().
                ForMember(dest => dest.AuthorName, opt => opt.MapFrom(src => src.Author.FirstName + " " + src.Author.LastName))
                .ForMember(dest => dest.Categories, opt => opt.MapFrom(src => src.BookCategories.Select(bc => bc.Category)));

            CreateMap<BookInsertRequest, Book>();

            CreateMap<BookUpdateRequest, Book>();
        }
    }
}
