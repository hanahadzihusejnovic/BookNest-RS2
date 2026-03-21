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
    public class CartService : BaseCRUDService<CartResponse, BaseSearchObject, Cart, CartInsertRequest, CartUpdateRequest>, ICartService
    {
        private readonly BookNestDbContext _dbContext;

        public CartService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<PagedResult<CartResponse>> GetAsync(BaseSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Carts
                         .Include(c => c.CartItems)
                             .ThenInclude(ci => ci.Book)
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

            var list = await query.ToListAsync(cancellationToken);

            var mapped = _mapper.Map<List<CartResponse>>(list);

            return new PagedResult<CartResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<CartResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                              .Include(c => c.CartItems)
                                .ThenInclude(ci => ci.Book)
                                .ThenInclude(b => b.Author)
                               .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

            if (cart == null)
            {
                return null;
            }

            return _mapper.Map<CartResponse>(cart);
        }

        public async Task<CartResponse> GetUserCartAsync(int userId, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                              .Include(c => c.CartItems)
                                .ThenInclude(ci => ci.Book)
                                .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                cart = new Cart
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow
                };

                _dbContext.Carts.Add(cart);
                await _dbContext.SaveChangesAsync(cancellationToken);

                cart = await _dbContext.Carts
                    .Include(c => c.CartItems)
                        .ThenInclude(ci => ci.Book)
                    .FirstOrDefaultAsync(c => c.Id == cart.Id, cancellationToken);
            }

            return _mapper.Map<CartResponse>(cart!);
        }

        public async Task<CartResponse> AddItemToCartAsync(int userId, CartItemInsertRequest request, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                cart = new Cart
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow
                };
                _dbContext.Carts.Add(cart);
                await _dbContext.SaveChangesAsync(cancellationToken);
            }

            var book = await _dbContext.Books.FindAsync(new object[] { request.BookId }, cancellationToken);
            if (book == null)
            {
                throw new Exception("Book not found.");
            }

            var existingItem = cart.CartItems.FirstOrDefault(ci => ci.BookId == request.BookId);

            if (existingItem != null)
            {
                existingItem.Quantity += request.Quantity;
            }
            else
            {
                var cartItem = new CartItem
                {
                    CartId = cart.Id,
                    BookId = request.BookId,
                    Price = book.Price,
                    Quantity = request.Quantity
                };

                _dbContext.CartItems.Add(cartItem);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetUserCartAsync(userId, cancellationToken);
        }

        public async Task<CartResponse> UpdateCartItemAsync(int userId, int cartItemId, int quantity, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                throw new Exception("Cart not found.");
            }

            var cartItem = cart.CartItems.FirstOrDefault(ci => ci.Id == cartItemId);

            if (cartItem == null)
            {
                throw new Exception("Cart item not found.");
            }

            if (quantity <= 0)
            {
                throw new Exception("Quantity must be greater than 0.");
            }

            cartItem.Quantity = quantity;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetUserCartAsync(userId, cancellationToken);
        }

        public async Task<CartResponse> RemoveItemFromCartAsync(int userId, int cartItemId, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                throw new Exception("Cart not found.");
            }

            var cartItem = cart.CartItems.FirstOrDefault(ci => ci.Id == cartItemId);

            if (cartItem == null)
            {
                throw new Exception("Cart item not found.");
            }

            _dbContext.CartItems.Remove(cartItem);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetUserCartAsync(userId, cancellationToken);
        }

        public async Task<bool> ClearCartAsync(int userId, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                return false;
            }

            _dbContext.CartItems.RemoveRange(cart.CartItems);
            await _dbContext.SaveChangesAsync(cancellationToken);

            return true;
        }
    }
}
