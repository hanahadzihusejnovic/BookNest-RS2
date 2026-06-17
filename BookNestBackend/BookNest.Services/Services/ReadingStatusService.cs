using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;

namespace BookNest.Services.Services
{
    public class ReadingStatusService : BaseCRUDService<ReadingStatusResponse, ReadingStatusSearchObject, ReadingStatus, ReadingStatusInsertRequest, ReadingStatusUpdateRequest>, IReadingStatusService
    {
        private readonly BookNestDbContext _dbContext;

        public ReadingStatusService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<ReadingStatus> ApplyFilter(IQueryable<ReadingStatus> query, ReadingStatusSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(r => r.Name != null && r.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
