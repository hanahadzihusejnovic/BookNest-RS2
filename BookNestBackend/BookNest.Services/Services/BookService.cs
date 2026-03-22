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
    public class BookService : BaseCRUDService<BookResponse, BookSearchObject, Book, BookInsertRequest, BookUpdateRequest>, IBookService
    {
        private readonly BookNestDbContext _dbContext;
        public BookService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Book> ApplyFilter(IQueryable<Book> query, BookSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(b =>
                    (b.Title != null && b.Title.ToLower().Contains(lower)) ||
                    (b.Author != null && b.Author.FirstName.ToLower().Contains(lower))
                    );
            }

            if (!string.IsNullOrWhiteSpace(search.Title))
            {
                query = query.Where(b => b.Title != null &&
                                         b.Title.ToLower().Contains(search.Title.ToLower()));
            }

            if (search.AuthorId.HasValue)
            {
                query = query.Where(b => b.AuthorId == search.AuthorId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search.AuthorName))
            {
                query = query.Where(b => b.Author != null &&
                                         b.Author.FirstName.ToLower().Contains(search.AuthorName.ToLower()));
            }

            if (search.Price.HasValue)
            {
                query = query.Where(b => b.Price == search.Price.Value);
            }

            if (search.CategoryId.HasValue)
            {
                query = query.Where(b => b.BookCategories
                    .Any(bc => bc.CategoryId == search.CategoryId.Value));
            }

            return query;
        }

        public override async Task<PagedResult<BookResponse>> GetAsync(BookSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Books
                         .Include(b => b.Author)
                         .Include(b => b.BookCategories)
                         .ThenInclude(bc => bc.Category)
                         .Include(b => b.Reviews)
                         .ThenInclude(r => r.User)
                         .AsQueryable();

            query = ApplyFilter(query, search);

            if (search.CategoryId.HasValue)
            {
                query = query.OrderByDescending(b =>
                    b.Reviews.Any() ? b.Reviews.Average(r => r.Rating) : 0);
            }

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

            var mapped = _mapper.Map<List<BookResponse>>(list);

            return new PagedResult<BookResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<BookResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var book = await _dbContext.Books
                            .Include(b => b.Author)
                            .Include(b => b.BookCategories)
                            .ThenInclude(bc => bc.Category)
                            .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);

            if(book == null)
            {
                return null;
            }

            return _mapper.Map<BookResponse>(book);
        }

        public override async Task<BookResponse> CreateAsync(BookInsertRequest request, CancellationToken cancellationToken = default)
        {
            var book = _mapper.Map<Book>(request);

            _dbContext.Books.Add(book);
            await _dbContext.SaveChangesAsync();

            if(request.CategoryIds != null && request.CategoryIds.Count > 0)
            {
                foreach(var categoryId in request.CategoryIds)
                {
                    if(await _dbContext.Categories.AnyAsync(c => c.Id == categoryId))
                    {
                        var bookCategory = new BookCategory
                        {
                            BookId = book.Id,
                            CategoryId = categoryId
                        };
                        _dbContext.BookCategories.Add(bookCategory);
                    }
                }

                await _dbContext.SaveChangesAsync();
            }

            return await GetBookWithCategoryAsync(book.Id);
        }

        public override async Task<BookResponse?> UpdateAsync(int id, BookUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var book = await _dbContext.Books.FindAsync(id);

            if(book == null)
            {
                return null;
            }

            _mapper.Map(request, book);

            var existingCategories = await _dbContext.BookCategories
                .Where(bc => bc.BookId == book.Id)
                .ToListAsync();

            _dbContext.BookCategories.RemoveRange(existingCategories);

            if(request.CategoryIds != null && request.CategoryIds.Count > 0)
            {
                foreach(var categoryId in request.CategoryIds)
                {
                    if(await _dbContext.Categories.AnyAsync(c => c.Id == categoryId))
                    {
                        var bookCategory = new BookCategory
                        {
                            BookId = book.Id,
                            CategoryId = categoryId
                        };
                        _dbContext.BookCategories.Add(bookCategory);
                    }
                }
            }

            await _dbContext.SaveChangesAsync();
            return await GetBookWithCategoryAsync(book.Id);
        }

        private async Task<BookResponse> GetBookWithCategoryAsync(int bookId)
        {
            var book = await _dbContext.Books
                .Include(b => b.Author)
                .Include(b => b.BookCategories)
                .ThenInclude(bc => bc.Category)
                .FirstOrDefaultAsync(b => b.Id == bookId);

            if(book == null)
            {
                throw new InvalidOperationException("Book not found.");
            }

            var response = _mapper.Map<BookResponse>(book);

            response.Categories = book.BookCategories
                .Select(bc => new CategoryResponse
                {
                    Id = bc.Category.Id,
                    Name = bc.Category.Name
                }).ToList();

            return response;
        }

        public async Task<List<BookResponse>> GetRecommendedBooksAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
        {
            var myBookIds = await GetUserInteractedBookIds(userId, cancellationToken);

            var similarUserIds = await _dbContext.Orders
                .Where(o => o.UserId != userId &&
                            o.OrderItems.Any(oi => myBookIds.Contains(oi.BookId)))
                .Select(o => o.UserId)
                .Union(
                    _dbContext.Favorites
                        .Where(f => f.UserId != userId && myBookIds.Contains(f.BookId))
                        .Select(f => f.UserId)
                )
                .Union(
                    _dbContext.TBRLists
                        .Where(t => t.UserId != userId && myBookIds.Contains(t.BookId))
                        .Select(t => t.UserId)
                )
                .Distinct()
                .ToListAsync(cancellationToken);

            var collaborativeBookIds = await _dbContext.Orders
                .Where(o => similarUserIds.Contains(o.UserId))
                .SelectMany(o => o.OrderItems.Select(oi => oi.BookId))
                .Union(
                    _dbContext.Favorites
                        .Where(f => similarUserIds.Contains(f.UserId))
                        .Select(f => f.BookId)
                )
                .Union(
                    _dbContext.TBRLists
                        .Where(t => similarUserIds.Contains(t.UserId))
                        .Select(t => t.BookId)
                )
                .Where(bookId => !myBookIds.Contains(bookId))
                .Distinct()
                .ToListAsync(cancellationToken);

            var recommended = await _dbContext.Books
                                    .Include(b => b.Author)
                                    .Include(b => b.BookCategories)
                                        .ThenInclude(bc => bc.Category)  
                                    .Include(b => b.Reviews)
                                    .Where(b => collaborativeBookIds.Contains(b.Id))
                                    .OrderByDescending(b =>
                                        b.Reviews.Any() ? b.Reviews.Average(r => r.Rating) : 0)
                                    .Take(count)
                                    .ToListAsync(cancellationToken);

            return _mapper.Map<List<BookResponse>>(recommended);
        }

        private async Task<List<int>> GetUserInteractedBookIds(int userId, CancellationToken cancellationToken)
        {
            var purchased = await _dbContext.Orders
                .Where(o => o.UserId == userId)
                .SelectMany(o => o.OrderItems.Select(oi => oi.BookId))
                .ToListAsync(cancellationToken);

            var favorites = await _dbContext.Favorites
                .Where(f => f.UserId == userId)
                .Select(f => f.BookId)
                .ToListAsync(cancellationToken);

            var tbr = await _dbContext.TBRLists
                .Where(t => t.UserId == userId)
                .Select(t => t.BookId)
                .ToListAsync(cancellationToken);

            return purchased.Union(favorites).Union(tbr).Distinct().ToList();
        }

        public async Task<List<BookResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default)
        {
            var myBookIds = await GetUserInteractedBookIds(userId, cancellationToken);

            var preferredCategoryIds = await _dbContext.BookCategories
                .Where(bc => myBookIds.Contains(bc.BookId))
                .Select(bc => bc.CategoryId)
                .Distinct()
                .ToListAsync(cancellationToken);

            IQueryable<Book> query = _dbContext.Books
                .Include(b => b.Author)
                .Include(b => b.BookCategories)
                    .ThenInclude(bc => bc.Category)
                .Include(b => b.Reviews)
                .Where(b => !myBookIds.Contains(b.Id));

            if (preferredCategoryIds.Any())
            {
                query = query.Where(b =>
                    b.BookCategories.Any(bc => preferredCategoryIds.Contains(bc.CategoryId)));
            }

            var books = await query
                .OrderByDescending(b =>
                    b.Reviews.Any() ? b.Reviews.Average(r => r.Rating) : 0)
                .Take(count)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<BookResponse>>(books);
        }
    }
}
