using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class EventTypeProfile : Profile
    {
        public EventTypeProfile()
        {
            CreateMap<EventType, EventTypeResponse>();
            CreateMap<EventTypeInsertRequest, EventType>();
            CreateMap<EventTypeUpdateRequest, EventType>();
        }
    }
}
