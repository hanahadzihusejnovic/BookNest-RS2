using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class ReservationStatusProfile : Profile
    {
        public ReservationStatusProfile()
        {
            CreateMap<ReservationStatus, ReservationStatusResponse>();
            CreateMap<ReservationStatusInsertRequest, ReservationStatus>();
            CreateMap<ReservationStatusUpdateRequest, ReservationStatus>();
        }
    }
}
