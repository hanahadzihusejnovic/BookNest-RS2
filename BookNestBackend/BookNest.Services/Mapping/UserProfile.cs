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
    public class UserProfile : Profile
    {
        public UserProfile()
        {
            CreateMap<User, UserResponse>()
                .ForMember(dest => dest.Roles, opt => opt.MapFrom(src => src.UserRoles.Select(ur => ur.Role)));

            CreateMap<UserInsertRequest, User>();

            CreateMap<UserUpdateRequest, User>();

            CreateMap<UserSelfUpdateRequest, User>();
        }
    }
}
