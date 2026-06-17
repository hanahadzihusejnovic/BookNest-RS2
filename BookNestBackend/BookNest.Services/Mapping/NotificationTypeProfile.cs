using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class NotificationTypeProfile : Profile
    {
        public NotificationTypeProfile()
        {
            CreateMap<NotificationType, NotificationTypeResponse>();
            CreateMap<NotificationTypeInsertRequest, NotificationType>();
            CreateMap<NotificationTypeUpdateRequest, NotificationType>();
        }
    }
}
