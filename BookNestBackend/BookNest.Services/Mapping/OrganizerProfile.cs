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
    public class OrganizerProfile : Profile
    {
        public OrganizerProfile()
        {
            CreateMap<Organizer, OrganizerResponse>()
                .ForMember(dest => dest.Events, opt => opt.MapFrom(src => src.Events));

            CreateMap<OrganizerInsertRequest, Organizer>();

            CreateMap<OrganizerUpdateRequest, Organizer>();
        }
    }
}
