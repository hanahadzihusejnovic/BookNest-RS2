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
    public class EventProfile : Profile
    {
        public EventProfile()
        {
            CreateMap<Event, EventResponse>()
                .ForMember(dest => dest.EventCategoryName, opt => opt.MapFrom(src => src.EventCategory.Name))
                .ForMember(dest => dest.OrganizerName, opt => opt.MapFrom(src => src.Organizer.FirstName + " " + src.Organizer.LastName))
                .ForMember(dest => dest.EventType, opt => opt.MapFrom(src => src.EventType.ToString()));

            CreateMap<EventInsertRequest, Event>();

            CreateMap<EventUpdateRequest, Event>();
        }
    }
}
