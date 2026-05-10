using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class CategoryProfile : Profile
    {
        public CategoryProfile()
        {
            CreateMap<Category, CategoryResponse>();

            CreateMap<CategoryInserRequest, Category>();
            
            CreateMap<CategoryUpdateRequest, Category>();
        }
    }
}
