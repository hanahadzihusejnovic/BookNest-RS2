using AutoMapper;
using BookNest.Model.Exceptions;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class CountryService : BaseCRUDService<CountryResponse, CountrySearchObject, Country, CountryInsertRequest, CountryUpdateRequest>, ICountryService
    {
        private readonly BookNestDbContext _dbContext;

        public CountryService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(c =>
                    c.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }

        public override async Task<PagedResult<CountryResponse>> GetAsync(CountrySearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Countries.AsQueryable();

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

            var list = await query
                .OrderBy(c => c.Name)
                .ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<CountryResponse>>(list);

            return new PagedResult<CountryResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<CountryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var country = await _dbContext.Countries
                .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

            if (country == null)
            {
                throw new NotFoundException("Country not found.");
            }

            return _mapper.Map<CountryResponse>(country);
        }

        public override async Task<CountryResponse?> UpdateAsync(int id, CountryUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var country = await _dbContext.Countries
                .FindAsync(new object[] { id }, cancellationToken);

            if (country == null)
            {
                throw new NotFoundException("Country not found.");
            }

            _mapper.Map(request, country);

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}