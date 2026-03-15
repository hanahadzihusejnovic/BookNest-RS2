using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
        Task<UserResponse> RegisterAsync(UserInsertRequest request, CancellationToken cancellationToken = default);
        Task<User?> GetByEmailAsync(string email);
        Task CreatePasswordResetTokenAsync(int userId, string token, DateTime expiresAt);
        Task<bool> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
