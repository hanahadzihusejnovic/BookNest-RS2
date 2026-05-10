using AutoMapper;
using BookNest.Model.Enums;
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
    public class TBRListService : BaseService<TBRListResponse, BaseSearchObject, TBRList>, ITBRListService
    {
        private readonly BookNestDbContext _dbContext;

        public TBRListService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<PagedResult<TBRListResponse>> GetAsync(BaseSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.TBRLists
                         .Include(t => t.Book)
                         .ThenInclude(b => b.Author)
                         .AsQueryable();

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
                .OrderByDescending(t => t.AddedAt)
                .ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<TBRListResponse>>(list);

            return new PagedResult<TBRListResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<TBRListResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var tbrItem = await _dbContext.TBRLists
                               .Include(t => t.Book)
                               .ThenInclude(b => b.Author)
                               .FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

            if (tbrItem == null)
            {
                throw new NotFoundException("Book not found in TBR list.");
            }

            return _mapper.Map<TBRListResponse>(tbrItem);
        }

        public async Task<List<TBRListResponse>> GetUserTBRListAsync(int userId, ReadingStatus? status = null, CancellationToken cancellationToken = default)
        {
            var query = _dbContext.TBRLists
                .Include(t => t.Book)
                    .ThenInclude(b => b.Author)
                .Where(t => t.UserId == userId);

            if (status.HasValue)
            {
                query = query.Where(t => t.ReadingStatus == status.Value);
            }

            var tbrList = await query
                .OrderByDescending(t => t.AddedAt)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<TBRListResponse>>(tbrList);
        }

        public async Task<TBRListResponse> AddToTBRListAsync(int userId, TBRListInsertRequest request, CancellationToken cancellationToken = default)
        {
            var existing = await _dbContext.TBRLists
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == request.BookId, cancellationToken);

            if (existing != null)
            {
                throw new BusinessException("Book is already in TBR list.");
            }

            var book = await _dbContext.Books.FindAsync(new object[] { request.BookId }, cancellationToken);
            if (book == null)
            {
                throw new NotFoundException("Book not found.");
            }

            var tbrItem = new TBRList
            {
                UserId = userId,
                BookId = request.BookId,
                ReadingStatus = request.ReadingStatus,
                AddedAt = DateTime.UtcNow
            };

            _dbContext.TBRLists.Add(tbrItem);
            await _dbContext.SaveChangesAsync(cancellationToken);

            var created = await _dbContext.TBRLists
                .Include(t => t.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(t => t.Id == tbrItem.Id, cancellationToken);

            return _mapper.Map<TBRListResponse>(created!);
        }

        public async Task<TBRListResponse> UpdateTBRListStatusAsync(int userId, int bookId, ReadingStatus status, CancellationToken cancellationToken = default)
        {
            var tbrItem = await _dbContext.TBRLists
                .Include(t => t.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == bookId, cancellationToken);

            if (tbrItem == null)
            {
                throw new NotFoundException("Book not found in TBR list.");
            }

            tbrItem.ReadingStatus = status;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return _mapper.Map<TBRListResponse>(tbrItem);
        }

        public async Task<bool> RemoveFromTBRListAsync(int userId, int bookId, CancellationToken cancellationToken = default)
        {
            var tbrItem = await _dbContext.TBRLists
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == bookId, cancellationToken);

            if (tbrItem == null)
            {
                throw new NotFoundException("Book not found in TBR list.");
            }

            _dbContext.TBRLists.Remove(tbrItem);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return true;
        }

        public async Task<bool> IsBookInTBRListAsync(int userId, int bookId, CancellationToken cancellationToken = default)
        {
            return await _dbContext.TBRLists
                .AnyAsync(t => t.UserId == userId && t.BookId == bookId, cancellationToken);
        }
    }
}
