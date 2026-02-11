using AutoMapper;
using BookNest.Model.Enums;
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
    public class TBRListService : BaseService<TBRListResponse, BaseSearchObject, TBRList>, ITBRListService
    {
        private readonly BookNestDbContext _dbContext;

        public TBRListService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
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

            return tbrList.Select(MapToTBRListResponse).ToList();
        }

        public async Task<TBRListResponse> AddToTBRListAsync(int userId, TBRListInsertRequest request, CancellationToken cancellationToken = default)
        {
            // Provjeri da li knjiga već postoji u TBR listi
            var existing = await _dbContext.TBRLists
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == request.BookId, cancellationToken);

            if (existing != null)
            {
                throw new Exception("Book is already in TBR list.");
            }

            // Provjeri da li knjiga postoji
            var book = await _dbContext.Books.FindAsync(new object[] { request.BookId }, cancellationToken);
            if (book == null)
            {
                throw new Exception("Book not found.");
            }

            // Dodaj u TBR listu
            var tbrItem = new TBRList
            {
                UserId = userId,
                BookId = request.BookId,
                ReadingStatus = request.ReadingStatus,
                AddedAt = DateTime.UtcNow
            };

            _dbContext.TBRLists.Add(tbrItem);
            await _dbContext.SaveChangesAsync(cancellationToken);

            // Vrati kreirani item sa Book podacima
            var created = await _dbContext.TBRLists
                .Include(t => t.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(t => t.Id == tbrItem.Id, cancellationToken);

            return MapToTBRListResponse(created!);
        }

        public async Task<TBRListResponse> UpdateTBRListStatusAsync(int userId, int bookId, ReadingStatus status, CancellationToken cancellationToken = default)
        {
            var tbrItem = await _dbContext.TBRLists
                .Include(t => t.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == bookId, cancellationToken);

            if (tbrItem == null)
            {
                throw new Exception("Book not found in TBR list.");
            }

            tbrItem.ReadingStatus = status;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return MapToTBRListResponse(tbrItem);
        }

        public async Task<bool> RemoveFromTBRListAsync(int userId, int bookId, CancellationToken cancellationToken = default)
        {
            var tbrItem = await _dbContext.TBRLists
                .FirstOrDefaultAsync(t => t.UserId == userId && t.BookId == bookId, cancellationToken);

            if (tbrItem == null)
            {
                return false;
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

        private TBRListResponse MapToTBRListResponse(TBRList tbrItem)
        {
            var author = tbrItem.Book.Author;

            return new TBRListResponse
            {
                Id = tbrItem.Id,
                UserId = tbrItem.UserId,
                BookId = tbrItem.BookId,
                BookTitle = tbrItem.Book.Title,
                BookAuthor = author != null ? $"{author.FirstName} {author.LastName}" : "Unknown",
                BookImageUrl = tbrItem.Book.CoverImageUrl ?? string.Empty,
                BookPrice = tbrItem.Book.Price,
                ReadingStatus = tbrItem.ReadingStatus,
                AddedAt = tbrItem.AddedAt
            };
        }
    }
}
