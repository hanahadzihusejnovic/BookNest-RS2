using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Interfaces
{
    public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserResponse?> UpdateSelfAsync(int userId, UserSelfUpdateRequest request, CancellationToken cancellationToken = default);
    }
}
