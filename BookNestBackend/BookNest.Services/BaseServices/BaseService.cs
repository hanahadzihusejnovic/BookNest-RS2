using BookNest.Services.BaseInterfaces;
using BookNest.Services.Database;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BookNest.Model.SearchObjects;
using BookNest.Model.Responses;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.BaseServices
{
    public abstract class BaseService<T, TSearch, TEntity> : IBaseService<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TEntity : class
    {
        private readonly BookNestDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(BookNestDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper; 
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search, CancellationToken cancellationToken)
        {
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);

            int? totalCount = null;

            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync(cancellationToken);
            }

            if(!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * (search.PageSize ?? 20));
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }

            var list = await query.ToListAsync(cancellationToken);
            return new PagedResult<T>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }

        public virtual async Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Set<TEntity>().FindAsync(new object[] { id }, cancellationToken);

            if(entity == null)
            {
                return null;
            }

            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity)
        {
            return _mapper.Map<T>(entity);
        }        
    }
}
