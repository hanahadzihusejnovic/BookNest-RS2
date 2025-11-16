using BookNest.Services.BaseInterfaces;
using BookNest.Services.Database;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.BaseServices
{
    public abstract class BaseService<T, TEntity> : IBaseService<T>
        where T : class
        where TEntity : class
    {
        private readonly BookNestDbContext _context;
        protected readonly IMapper _mapper;

        public BaseService(BookNestDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper; 
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
