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
    public class AuthorService : BaseCRUDService<AuthorResponse, Author, AuthorInsertRequest, AuthorUpdateRequest>, IAuthorService
    {
        private readonly BookNestDbContext _dbContext;
        public AuthorService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<AuthorResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var author = await _dbContext.Authors
                .Include(a => a.Books)
                .FirstOrDefaultAsync(a => a.Id == id, cancellationToken);

            if(author == null)
            {
                return null;
            }

            return MapToResponse(author);
        }
    }
}
