using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Database.Entities;
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using BookNest.Services.Security;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IPasswordHasher _hasher;
        private readonly IMapper _mapper;
        private readonly JwtSettings _jwtSettings;

        public AuthService(
            BookNestDbContext dbContext,
            IPasswordHasher hasher,
            IMapper mapper,
            IOptions<JwtSettings> jwtSettings)
        {
            _dbContext = dbContext;
            _hasher = hasher;
            _mapper = mapper;
            _jwtSettings = jwtSettings.Value;
        }

        public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == request.Username, cancellationToken);

            if (user == null)
            {
                return null; 
            }

            if (!_hasher.Verify(request.Password, user.PasswordHash))
            {
                return null; 
            }

            if (!user.IsActive)
            {
                throw new Exception("User account is deactivated.");
            }

            var token = GenerateJwtToken(user);
            var expiresAt = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationMinutes);

            return new LoginResponse
            {
                UserId = user.Id,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                EmailAddress = user.EmailAddress,
                Roles = user.UserRoles.Select(ur => ur.Role.Name).ToList(),
                Token = token,
                ExpiresAt = expiresAt
            };
        }

        public async Task<UserResponse> RegisterAsync(UserInsertRequest request, CancellationToken cancellationToken = default)
        {
            var existingEmail = await _dbContext.Users
                .FirstOrDefaultAsync(u => u.EmailAddress == request.EmailAddress, cancellationToken);

            if (existingEmail != null)
            {
                throw new Exception("Email address already exists.");
            }

            var existingUsername = await _dbContext.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username, cancellationToken);

            if (existingUsername != null)
            {
                throw new Exception("Username already exists.");
            }

            var user = _mapper.Map<User>(request);
            user.PasswordHash = _hasher.Hash(request.Password);
            user.CreatedAt = DateTime.UtcNow;
            user.IsActive = true;

            _dbContext.Users.Add(user);
            await _dbContext.SaveChangesAsync(cancellationToken);

            if (request.RoleIds != null && request.RoleIds.Any())
            {
                foreach (var roleId in request.RoleIds)
                {
                    if (await _dbContext.Roles.AnyAsync(r => r.Id == roleId, cancellationToken))
                    {
                        var userRole = new UserRole
                        {
                            UserId = user.Id,
                            RoleId = roleId,
                            DateAssigned = DateTime.UtcNow
                        };
                        _dbContext.UserRoles.Add(userRole);
                    }
                }
                await _dbContext.SaveChangesAsync(cancellationToken);
            }

            var createdUser = await _dbContext.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == user.Id, cancellationToken);

            var response = _mapper.Map<UserResponse>(createdUser);

            response.Roles = createdUser!.UserRoles
                .Select(ur => new RoleResponse
                {
                    Id = ur.Role.Id,
                    Name = ur.Role.Name
                }).ToList();

            return response;
        }

        private string GenerateJwtToken(User user)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.EmailAddress),
                new Claim("FirstName", user.FirstName),
                new Claim("LastName", user.LastName)
            };

            foreach (var userRole in user.UserRoles)
            {
                claims.Add(new Claim(ClaimTypes.Role, userRole.Role.Name));
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.SecretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _jwtSettings.Issuer,
                audience: _jwtSettings.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public async Task<User?> GetByEmailAsync(string email)
        {
            return await _dbContext.Users
                .FirstOrDefaultAsync(u => u.EmailAddress == email);
        }

        public async Task CreatePasswordResetTokenAsync(int userId, string token, DateTime expiresAt)
        {
            var resetToken = new PasswordResetToken
            {
                UserId = userId,
                Token = token,
                ExpiresAt = expiresAt,
                IsUsed = false,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.PasswordResetTokens.Add(resetToken);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
        {
            if (request.NewPassword != request.ConfirmPassword)
                throw new Exception("Passwords do not match.");

            var resetToken = await _dbContext.PasswordResetTokens
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Token == request.Token
                                        && !t.IsUsed
                                        && t.ExpiresAt > DateTime.UtcNow);

            if (resetToken == null)
                throw new Exception("Invalid or expired token.");

            resetToken.User.PasswordHash = _hasher.Hash(request.NewPassword);
            resetToken.IsUsed = true;

            await _dbContext.SaveChangesAsync();
            return true;
        }
    }
}
