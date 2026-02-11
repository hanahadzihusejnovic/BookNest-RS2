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
    public interface ICartService : IBaseCRUDService<CartResponse, BaseSearchObject, CartInsertRequest, CartUpdateRequest>
    {
        Task<CartResponse> GetUserCartAsync(int userId, CancellationToken cancellationToken = default);
        Task<CartResponse> AddItemToCartAsync(int userId, CartItemInsertRequest request, CancellationToken cancellationToken = default);
        Task<CartResponse> UpdateCartItemAsync(int userId, int cartItemId, int quantity, CancellationToken cancellationToken = default);
        Task<CartResponse> RemoveItemFromCartAsync(int userId, int cartItemId, CancellationToken cancellationToken = default);
        Task<bool> ClearCartAsync(int userId, CancellationToken cancellationToken = default);
    }
}
