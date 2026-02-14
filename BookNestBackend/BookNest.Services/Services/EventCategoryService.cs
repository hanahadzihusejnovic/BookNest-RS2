using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Services
{
    public class EventCategoryService : BaseCRUDService<EventCategoryResponse, EventCategorySearchObject, EventCategory, EventCategoryInsertRequest, EventCategoryUpdateRequest>, IEventCategoryService
    {
        private readonly BookNestDbContext _dbContext;
        public EventCategoryService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            
        }

        protected override IQueryable<EventCategory> ApplyFilter(IQueryable<EventCategory> query, EventCategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(
                    ec => ec.Name != null && ec.Name.ToLower().Contains(lower)
                );
            }

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(ec => ec.Name != null && ec.Name.ToLower().Contains(search.Name.ToLower()));
            }
   
            return query;
        }

        public override async Task<PagedResult<EventCategoryResponse>> GetAsync(EventCategorySearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.EventCategories
                         .Include(ec => ec.Events)
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

            var mapped = _mapper.Map<List<EventCategoryResponse>>(list);

            return new PagedResult<EventCategoryResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<EventCategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var eventCategory = await _dbContext.EventCategories
                                      .Include(ec => ec.Events)
                                      .FirstOrDefaultAsync(ec => ec.Id == id, cancellationToken);

            if(eventCategory == null)
            {
                return null;
            }

            return _mapper.Map<EventCategoryResponse>(eventCategory);
        }

        public override async Task<EventCategoryResponse?> UpdateAsync(int id, EventCategoryUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var eventCategory = await _dbContext.EventCategories.FindAsync(new object[] { id }, cancellationToken);

            if (eventCategory == null)
            {
                return null;
            }

            _mapper.Map(request, eventCategory);

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}
