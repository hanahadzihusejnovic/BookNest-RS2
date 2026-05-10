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
    public class CityService : BaseCRUDService<CityResponse, CitySearchObject, City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        private readonly BookNestDbContext _dbContext;

        public CityService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
            }

            if (search.CountryId.HasValue)
            {
                query = query.Where(c => c.CountryId == search.CountryId.Value);
            }

            return query;
        }

        public override async Task<PagedResult<CityResponse>> GetAsync(CitySearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Cities
                .Include(c => c.Country)
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

            var list = await query.OrderBy(c => c.Name).ToListAsync(cancellationToken);
            var mapped = _mapper.Map<List<CityResponse>>(list);

            return new PagedResult<CityResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<CityResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var city = await _dbContext.Cities
                .Include(c => c.Country)
                .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

            if (city == null)
                throw new NotFoundException("City not found.");

            return _mapper.Map<CityResponse>(city);
        }

        public override async Task<CityResponse> CreateAsync(CityInsertRequest request, CancellationToken cancellationToken = default)
        {
            var city = _mapper.Map<City>(request);

            _dbContext.Cities.Add(city);

            await _dbContext.SaveChangesAsync(cancellationToken);
            return await GetByIdAsync(city.Id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve created city.");
        }

        public override async Task<CityResponse?> UpdateAsync(int id, CityUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var city = await _dbContext.Cities.FindAsync(id);

            if (city == null)
                throw new NotFoundException("City not found.");

            _mapper.Map(request, city);

            await _dbContext.SaveChangesAsync(cancellationToken);
            return await GetByIdAsync(id, cancellationToken);
        }
    }
}