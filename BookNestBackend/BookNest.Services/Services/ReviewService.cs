using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database.Entities;
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class ReviewService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        private readonly BookNestDbContext _dbContext;

        public ReviewService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.BookId.HasValue)
            {
                query = query.Where(r => r.BookId == search.BookId.Value);
            }

            if (search.EventId.HasValue)
            {
                query = query.Where(r => r.EventId == search.EventId.Value);
            }

            if (search.MinRating.HasValue)
            {
                query = query.Where(r => r.Rating >= search.MinRating.Value);
            }

            if (search.MaxRating.HasValue)
            {
                query = query.Where(r => r.Rating <= search.MaxRating.Value);
            }

            return query;
        }

        public override async Task<PagedResult<ReviewResponse>> GetAsync(ReviewSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Book)
                .Include(r => r.Event)
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

            var list = await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<ReviewResponse>>(list);

            return new PagedResult<ReviewResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var review = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Book)
                .Include(r => r.Event)
                .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);

            if (review == null)
            {
                return null;
            }

            return _mapper.Map<ReviewResponse>(review);
        }

        protected override async Task BeforeInsert(Review entity, ReviewInsertRequest request, CancellationToken cancellationToken = default)
        {
            if (!request.BookId.HasValue && !request.EventId.HasValue)
            {
                throw new Exception("Either BookId or EventId must be provided.");
            }

            if (request.BookId.HasValue && request.EventId.HasValue)
            {
                throw new Exception("Cannot review both Book and Event at the same time.");
            }

            if (request.BookId.HasValue)
            {
                var book = await _dbContext.Books.FindAsync(new object[] { request.BookId.Value }, cancellationToken);
                if (book == null)
                {
                    throw new Exception("Book not found.");
                }
            }

            if (request.EventId.HasValue)
            {
                var eventEntity = await _dbContext.Events.FindAsync(new object[] { request.EventId.Value }, cancellationToken);
                if (eventEntity == null)
                {
                    throw new Exception("Event not found.");
                }
            }

            entity.CreatedAt = DateTime.UtcNow;

            await base.BeforeInsert(entity, request, cancellationToken);
        }

        public async Task<List<ReviewResponse>> GetBookReviewsAsync(int bookId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Book)
                .Where(r => r.BookId == bookId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<ReviewResponse>>(reviews);
        }

        public async Task<List<ReviewResponse>> GetEventReviewsAsync(int eventId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Event)
                .Where(r => r.EventId == eventId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<ReviewResponse>>(reviews);
        }

        public async Task<List<ReviewResponse>> GetUserReviewsAsync(int userId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbContext.Reviews
                .Include(r => r.User)
                .Include(r => r.Book)
                .Include(r => r.Event)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<ReviewResponse>>(reviews);
        }

        public async Task<double> GetBookAverageRatingAsync(int bookId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbContext.Reviews
                .Where(r => r.BookId == bookId)
                .ToListAsync(cancellationToken);

            if (!reviews.Any())
            {
                return 0;
            }

            return reviews.Average(r => r.Rating);
        }

        public async Task<double> GetEventAverageRatingAsync(int eventId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbContext.Reviews
                .Where(r => r.EventId == eventId)
                .ToListAsync(cancellationToken);

            if (!reviews.Any())
            {
                return 0;
            }

            return reviews.Average(r => r.Rating);
        }
    }
}
