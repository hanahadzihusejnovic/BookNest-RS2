using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;

namespace BookNest.Services.Mapping
{
    public class ReadingStatusProfile : Profile
    {
        public ReadingStatusProfile()
        {
            CreateMap<ReadingStatus, ReadingStatusResponse>();
            CreateMap<ReadingStatusInsertRequest, ReadingStatus>();
            CreateMap<ReadingStatusUpdateRequest, ReadingStatus>();
        }
    }
}
