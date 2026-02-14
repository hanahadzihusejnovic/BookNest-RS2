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
    public class OrganizerService : BaseCRUDService<OrganizerResponse, OrganizerSearchObject, Organizer, OrganizerInsertRequest, OrganizerUpdateRequest>, IOrganizerService
    {
        private readonly BookNestDbContext _dbContext;
        public OrganizerService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Organizer> ApplyFilter(IQueryable<Organizer> query, OrganizerSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(o =>
                    (o.FirstName != null && o.FirstName.ToLower().Contains(lower)) ||
                    (o.LastName != null && o.LastName.ToLower().Contains(lower)) ||
                    (o.ContactEmail != null && o.ContactEmail.ToLower().Contains(lower)) 
                    );
            }

            if (!string.IsNullOrWhiteSpace(search.FirstName))
            {
                query = query.Where(o => o.FirstName != null &&
                                         o.FirstName.ToLower().Contains(search.FirstName.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.LastName))
            {
                query = query.Where(o => o.LastName != null &&
                                         o.LastName.ToLower().Contains(search.LastName.ToLower()));
            }

            if (!string.IsNullOrWhiteSpace(search.ContactEmail))
            {
                query = query.Where(o => o.ContactEmail != null &&
                                         o.ContactEmail.ToLower().Contains(search.ContactEmail.ToLower()));
            }

            return query;
        }

        public override async Task<PagedResult<OrganizerResponse>> GetAsync(OrganizerSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Organizers
                         .Include(o => o.Events)
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

            var mapped = _mapper.Map<List<OrganizerResponse>>(list);

            return new PagedResult<OrganizerResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<OrganizerResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var organizer = await _dbContext.Organizers
                                    .Include(o => o.Events)
                                    .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if(organizer == null)
            {
                return null;
            }

            return _mapper.Map<OrganizerResponse>(organizer);
        }

        public override async Task<OrganizerResponse?> UpdateAsync(int id, OrganizerUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var organizer = await _dbContext.Organizers.FindAsync(new object[] { id }, cancellationToken);

            if (organizer == null)
            {
                return null;
            }

            _mapper.Map(request, organizer);

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}
