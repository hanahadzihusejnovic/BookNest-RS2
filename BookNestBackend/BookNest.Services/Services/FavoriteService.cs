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
    public class FavoriteService : BaseService<FavoriteResponse, BaseSearchObject, Favorite>, IFavoriteService
    {
        private readonly BookNestDbContext _dbContext;

        public FavoriteService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public async Task<List<FavoriteResponse>> GetUserFavoritesAsync(int userId, CancellationToken cancellationToken = default)
        {
            var favorites = await _dbContext.Favorites
                .Include(f => f.Book)
                    .ThenInclude(b => b.Author)
                .Where(f => f.UserId == userId)
                .ToListAsync(cancellationToken);

            return favorites.Select(MapToFavoriteResponse).ToList();
        }

        public async Task<FavoriteResponse> AddToFavoritesAsync(int userId, FavoriteInsertRequest request, CancellationToken cancellationToken = default)
        {
            var existing = await _dbContext.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.BookId == request.BookId, cancellationToken);

            if (existing != null)
            {
                throw new Exception("Book is already in favorites.");
            }

            var book = await _dbContext.Books.FindAsync(new object[] { request.BookId }, cancellationToken);
            if (book == null)
            {
                throw new Exception("Book not found.");
            }
            
            var favorite = new Favorite
            {
                UserId = userId,
                BookId = request.BookId
            };

            _dbContext.Favorites.Add(favorite);
            await _dbContext.SaveChangesAsync(cancellationToken);

            var created = await _dbContext.Favorites
                .Include(f => f.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(f => f.Id == favorite.Id, cancellationToken);

            return MapToFavoriteResponse(created!);
        }

        public async Task<bool> RemoveFromFavoritesAsync(int userId, int bookId, CancellationToken cancellationToken = default)
        {
            var favorite = await _dbContext.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.BookId == bookId, cancellationToken);

            if (favorite == null)
            {
                return false;
            }

            _dbContext.Favorites.Remove(favorite);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return true;
        }

        public async Task<bool> IsBookInFavoritesAsync(int userId, int bookId, CancellationToken cancellationToken = default)
        {
            return await _dbContext.Favorites
                .AnyAsync(f => f.UserId == userId && f.BookId == bookId, cancellationToken);
        }

        private FavoriteResponse MapToFavoriteResponse(Favorite favorite)
        {
            var author = favorite.Book.Author;

            return new FavoriteResponse
            {
                Id = favorite.Id,
                UserId = favorite.UserId,
                BookId = favorite.BookId,
                BookTitle = favorite.Book.Title,
                BookAuthor = author != null ? $"{author.FirstName} {author.LastName}" : "Unknown",
                BookImageUrl = favorite.Book.CoverImageUrl ?? string.Empty,
                BookPrice = favorite.Book.Price
            };
        }
    }
}
