using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
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
    public class AuthorService : BaseCRUDService<AuthorResponse, AuthorSearchObject, Author, AuthorInsertRequest, AuthorUpdateRequest>, IAuthorService
    {
        private readonly BookNestDbContext _dbContext;
        public AuthorService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Author> ApplyFilter(IQueryable<Author> query, AuthorSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(a =>
                    (a.FirstName != null && a.FirstName.ToLower().Contains(lower)) ||
                    (a.LastName != null && a.LastName.ToLower().Contains(lower))
                    );
            }

            if (!string.IsNullOrWhiteSpace(search.FirstName))
            {
                query = query.Where(a => a.FirstName != null &&
                                         a.FirstName.ToLower().Contains(search.FirstName.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.LastName))
            {
                query = query.Where(a => a.LastName != null &&
                                         a.LastName.ToLower().Contains(search.LastName.ToLower()));
            }

            return query;
        }

        public override async Task<PagedResult<AuthorResponse>> GetAsync(AuthorSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Authors
                         .Include(a => a.Books)
                         .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
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

            var mapped = list.Select(MapToResponse).ToList();

            return new PagedResult<AuthorResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
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
