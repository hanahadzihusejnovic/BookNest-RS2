using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class CountryProfile : Profile
    {
        public CountryProfile()
        {
            CreateMap<Country, CountryResponse>();
            CreateMap<CountryInsertRequest, Country>();
            CreateMap<CountryUpdateRequest, Country>();
        }
    }
}