using AutoMapper;
using BookNest.Model.Exceptions;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using BookNest.Services.Security;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IPasswordHasher _hasher;

        public UserService(BookNestDbContext dbContext, IMapper mapper, IPasswordHasher hasher) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _hasher = hasher;
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(u => 
                    (u.FirstName != null && u.FirstName.ToLower().Contains(lower)) ||
                    (u.LastName != null && u.LastName.ToLower().Contains(lower)) ||
                    (u.EmailAddress != null && u.EmailAddress.ToLower().Contains(lower)) ||
                    (u.Username != null && u.Username.ToLower().Contains(lower))
                    );
            }

            if (!string.IsNullOrWhiteSpace(search.FirstName))
            {
                query = query.Where(u => u.FirstName != null &&
                                         u.FirstName.ToLower().Contains(search.FirstName.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.LastName))
            {
                query = query.Where(u => u.LastName != null &&
                                         u.LastName.ToLower().Contains(search.LastName.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.EmailAddress))
            {
                query = query.Where(u => u.EmailAddress != null &&
                                         u.EmailAddress.ToLower().Contains(search.EmailAddress.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.Username))
            {
                query = query.Where(u => u.Username != null &&
                                         u.Username.ToLower().Contains(search.Username.ToLower()));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(u => u.IsActive == search.IsActive.Value);
            }

            return query;
        }

        public override async Task<PagedResult<UserResponse>> GetAsync(UserSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Users
                         .Include(u => u.UserRoles)
                             .ThenInclude(ur => ur.Role)
                         .Include(u => u.City)
                         .Include(u => u.Country)
                         .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if(search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync(cancellationToken);
            }

            if (!search.RetrieveAll)
            {
                int skip = (search.Page ?? 0) * (search.PageSize ?? 20);
                int take = search.PageSize ?? 20;

                query = query.Skip(skip).Take(take);
            }

            var list = await query.ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<UserResponse>>(list);

            return new PagedResult<UserResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<UserResponse?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            var user = await _dbContext.Users
                             .Include(u => u.UserRoles)
                                 .ThenInclude(u => u.Role)
                             .Include(u => u.City)
                             .Include(u => u.Country)
                             .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
            
            if (user == null)
            {
                throw new NotFoundException("User not found.");
            }

            return _mapper.Map<UserResponse>(user);
        }

        protected override async Task BeforeInsert(User user, UserInsertRequest request, CancellationToken cancellationToken = default)
        {
            var existingMail = await _dbContext.Users.FirstOrDefaultAsync(em => em.EmailAddress == request.EmailAddress);

            if(existingMail != null)
            {
                throw new BusinessException("Email address already exists.");
            }

            var existingUsername = await _dbContext.Users.FirstOrDefaultAsync(eu => eu.Username == request.Username);
            
            if(existingUsername != null)
            {
                throw new BusinessException("Username already exists.");
            }

            await base.BeforeInsert(user, request, cancellationToken);
        }

        public override async Task<UserResponse> CreateAsync(UserInsertRequest request, CancellationToken cancellationToken = default)
        {
            throw new NotSupportedException("User registration is done through AuthService.RegisterAsync.");
        }

        protected override async Task BeforeUpdate(User entity, UserUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var existingMail = await _dbContext.Users
                .FirstOrDefaultAsync(em => em.EmailAddress == request.EmailAddress && em.Id != entity.Id, cancellationToken);

            if (existingMail != null)
            {
                throw new BusinessException("Email address already exists.");
            }

            var existingUsername = await _dbContext.Users
                .FirstOrDefaultAsync(eu => eu.Username == request.Username && eu.Id != entity.Id, cancellationToken);

            if (existingUsername != null)
            {
                throw new BusinessException("Username already exists.");
            }

            await base.BeforeUpdate(entity, request, cancellationToken);
        }

        public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users.FindAsync(id);

            if (user == null)
                throw new NotFoundException("User not found.");

            _mapper.Map(request, user);

            await BeforeUpdate(user, request, cancellationToken);

            if (!string.IsNullOrEmpty(request.Password))
            {
                user.PasswordHash = _hasher.Hash(request.Password);
            }

            await _dbContext.SaveChangesAsync();
            return await GetUserResponseWithRolesAsync(user.Id);
        }

        private async Task<UserResponse> GetUserResponseWithRolesAsync(int userId)
        {
            var user = await _dbContext.Users
                                .Include(u => u.UserRoles)
                                    .ThenInclude(ur => ur.Role)
                                .Include(u => u.City)
                                .Include(u => u.Country)
                                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                throw new NotFoundException("User not found."); 
            }

            var response = _mapper.Map<UserResponse>(user);

            response.Roles = user.UserRoles
                .Select(ur => new RoleResponse
                {
                    Id = ur.Role.Id,
                    Name = ur.Role.Name
                }).ToList();

            return response;
        }

        public async Task<UserResponse?> UpdateSelfAsync(int userId, UserSelfUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user == null) 
                throw new NotFoundException("User not found.");

            if (!string.IsNullOrEmpty(request.Username) && request.Username != user.Username)
            {
                var existingUsername = await _dbContext.Users
                    .FirstOrDefaultAsync(u => u.Username == request.Username && u.Id != userId, cancellationToken);

                if (existingUsername != null)
                    throw new BusinessException("Username already exists.");
            }

            _mapper.Map(request, user);

            await _dbContext.SaveChangesAsync(cancellationToken);

            var updatedUser = await _dbContext.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Include(u => u.City)
                .Include(u => u.Country)
                .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

            return _mapper.Map<UserResponse>(updatedUser);
        }

        public async Task DeactivateSelfAsync(int userId, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Users.FindAsync(new object[] { userId }, cancellationToken);
            if (user == null) 
                throw new NotFoundException("User not found.");

            user.IsActive = false;
            user.DeactivatedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
