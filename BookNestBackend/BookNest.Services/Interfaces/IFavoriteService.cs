using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Interfaces
{
    public interface IFavoriteService : IBaseService<FavoriteResponse, BaseSearchObject>
    {
        Task<List<FavoriteResponse>> GetUserFavoritesAsync(int userId, CancellationToken cancellationToken = default);
        Task<FavoriteResponse> AddToFavoritesAsync(int userId, FavoriteInsertRequest request, CancellationToken cancellationToken = default);
        Task<bool> RemoveFromFavoritesAsync(int userId, int bookId, CancellationToken cancellationToken = default);
        Task<bool> IsBookInFavoritesAsync(int userId, int bookId, CancellationToken cancellationToken = default);
    }
}
