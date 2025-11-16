using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
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
    public class BookService : BaseCRUDService<BookResponse, Book, BookInsertRequest, BookUpdateRequest>, IBookService
    {
        private readonly BookNestDbContext _dbContext;
        public BookService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
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

            return MapToResponse(book);
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

            var response = MapToResponse(book);

            response.Categories = book.BookCategories
                .Select(bc => new CategoryResponse
                {
                    Id = bc.Category.Id,
                    Name = bc.Category.Name
                }).ToList();

            return response;
        } 
    }
}
