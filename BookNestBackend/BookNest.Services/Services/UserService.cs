using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Services
{
    public class UserService : BaseCRUDService<UserResponse, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly BookNestDbContext _dbContext;
        public UserService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<UserResponse?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            var user = await _dbContext.Users
                             .Include(u => u.UserRoles)
                             .ThenInclude(u => u.Role)
                             .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

            if (user == null)
            {
                return null;
            }

            return MapToResponse(user);
        }

        public override async Task<UserResponse> CreateAsync(UserInsertRequest request, CancellationToken cancellationToken = default)
        {
            var user = _mapper.Map<User>(request);

            _dbContext.Users.Add(user);
            await _dbContext.SaveChangesAsync();


            if (request.RoleIds != null && request.RoleIds.Count > 0)
            {
                foreach (var roleId in request.RoleIds)
                {
                    if (await _dbContext.Roles.AnyAsync(r => r.Id == roleId))
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

                await _dbContext.SaveChangesAsync();
            }

            return await GetUserResponseWithRolesAsync(user.Id);
        }

        public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users.FindAsync(id);

            if(user == null)
            {
                return null;
            }

            _mapper.Map(request, user);

            var existingUserRoles = await _dbContext.UserRoles
                .Where(ur => ur.UserId == id)
                .ToListAsync();

            _dbContext.UserRoles.RemoveRange(existingUserRoles);

            if(request.RoleIds != null && request.RoleIds.Count > 0)
            {
                foreach(var roleId in request.RoleIds)
                {
                    if(await _dbContext.Roles.AnyAsync(r => r.Id == roleId))
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
            }

            await _dbContext.SaveChangesAsync();
            return await GetUserResponseWithRolesAsync(user.Id);
        }

        private async Task<UserResponse> GetUserResponseWithRolesAsync(int userId)
        {
            var user = await _dbContext.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if(user == null)
            {
                throw new InvalidOperationException("User not found."); 
            }

            var response = MapToResponse(user);

            response.Roles = user.UserRoles
                .Select(ur => new RoleResponse
                {
                    Id = ur.Role.Id,
                    Name = ur.Role.Name
                }).ToList();

            return response;
        }
    }
}
