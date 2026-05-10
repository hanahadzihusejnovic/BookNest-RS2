using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class EventProfile : Profile
    {
        public EventProfile()
        {
            CreateMap<Event, EventResponse>()
                .ForMember(dest => dest.EventCategoryName, opt => opt.MapFrom(src => src.EventCategory.Name))
                .ForMember(dest => dest.OrganizerName, opt => opt.MapFrom(src => src.Organizer.FirstName + " " + src.Organizer.LastName))
                .ForMember(dest => dest.EventType, opt => opt.MapFrom(src => src.EventType.ToString()))
                .ForMember(dest => dest.CityId, opt => opt.MapFrom(src => src.CityId))
                .ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.City != null ? src.City.Name : null))
                .ForMember(dest => dest.CountryId, opt => opt.MapFrom(src => src.CountryId))
                .ForMember(dest => dest.CountryName, opt => opt.MapFrom(src => src.Country != null ? src.Country.Name : null));

            CreateMap<EventInsertRequest, Event>();

            CreateMap<EventUpdateRequest, Event>();
        }
    }
}
