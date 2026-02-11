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

        public async Task<CartResponse> GetUserCartAsync(int userId, CancellationToken cancellationToken = default)
        {
            // Pronađi ili kreiraj korpu za korisnika
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                    .ThenInclude(ci => ci.Book)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null)
            {
                // Kreiraj novu korpu ako ne postoji
                cart = new Cart
                {
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow
                };

                _dbContext.Carts.Add(cart);
                await _dbContext.SaveChangesAsync(cancellationToken);

                // Učitaj ponovo sa related data
                cart = await _dbContext.Carts
                    .Include(c => c.CartItems)
                        .ThenInclude(ci => ci.Book)
                    .FirstOrDefaultAsync(c => c.Id == cart.Id, cancellationToken);
            }

            return MapToCartResponse(cart!);
        }

        public async Task<CartResponse> AddItemToCartAsync(int userId, CartItemInsertRequest request, CancellationToken cancellationToken = default)
        {
            // Pronađi ili kreiraj korpu
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

            // Provjeri da li knjiga postoji
            var book = await _dbContext.Books.FindAsync(new object[] { request.BookId }, cancellationToken);
            if (book == null)
            {
                throw new Exception("Book not found.");
            }

            // Provjeri da li knjiga već postoji u korpi
            var existingItem = cart.CartItems.FirstOrDefault(ci => ci.BookId == request.BookId);

            if (existingItem != null)
            {
                // Ažuriraj količinu
                existingItem.Quantity += request.Quantity;
            }
            else
            {
                // Dodaj novu stavku
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

        private CartResponse MapToCartResponse(Cart cart)
        {
            return new CartResponse
            {
                Id = cart.Id,
                UserId = cart.UserId,
                CreatedAt = cart.CreatedAt,
                CartItems = cart.CartItems.Select(ci => new CartItemResponse
                {
                    Id = ci.Id,
                    BookId = ci.BookId,
                    BookTitle = ci.Book.Title,
                    BookImageUrl = ci.Book.CoverImageUrl ?? string.Empty,
                    Price = ci.Price,
                    Quantity = ci.Quantity
                }).ToList()
            };
        }
    }
}
