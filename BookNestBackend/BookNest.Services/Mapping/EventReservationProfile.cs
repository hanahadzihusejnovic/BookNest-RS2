using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;
using BookNest.Model.Enums;

namespace BookNest.Services.Mapping
{
    public class EventReservationProfile : Profile
    {
        public EventReservationProfile()
        {
            CreateMap<EventReservation, EventReservationResponse>()
                .ForMember(dest => dest.UserFullName, opt => opt.MapFrom(src => src.User.FirstName + " " + src.User.LastName))
                .ForMember(dest => dest.UserEmail, opt => opt.MapFrom(src => src.User.EmailAddress))
                .ForMember(dest => dest.EventName, opt => opt.MapFrom(src => src.Event.Name))
                .ForMember(dest => dest.EventLocation, opt => opt.MapFrom(src =>
                    src.Event.EventType == EventType.Online
                        ? "Online"
                        : string.Join(", ", new[] { src.Event.Address, src.Event.City != null ? src.Event.City.Name : null, src.Event.Country != null ? src.Event.Country.Name : null }
                            .Where(s => !string.IsNullOrEmpty(s)))))
                .ForMember(dest => dest.Payment, opt => opt.MapFrom(src => src.Payment));

            CreateMap<EventReservationInsertRequest, EventReservation>();

            CreateMap<EventReservationUpdateRequest, EventReservation>();
        }
    }
}
