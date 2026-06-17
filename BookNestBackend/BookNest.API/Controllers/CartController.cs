using BookNest.API.BaseControllers;
using BookNest.Model.Constants;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CartController : BaseCRUDController<CartResponse, BaseSearchObject, CartInsertRequest, CartUpdateRequest>
    {
        private readonly ICartService _cartService;

        public CartController(ICartService cartService) : base(cartService)
        {
            _cartService = cartService;
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<PagedResult<CartResponse>> Get([FromQuery] BaseSearchObject search)
        {
            return await base.Get(search);
        }

        public override async Task<CartResponse?> GetById(int id)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return null;

            var cart = await base.GetById(id);
            if (cart == null) return null;

            var isAdmin = User.IsInRole(Roles.Admin);
            if (!isAdmin && cart.UserId != userId)
                throw new UnauthorizedAccessException("You do not have access to this cart.");

            return cart;
        }

        [HttpGet("my-cart")]
        public async Task<ActionResult<CartResponse>> GetMyCart()
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var cart = await _cartService.GetUserCartAsync(userId);
            return Ok(cart);
        }

        [HttpPost("add-item")]
        public async Task<ActionResult<CartResponse>> AddItem([FromBody] CartItemInsertRequest request)
        {
            
            var userId = GetCurrentUserId();

             if (userId == 0)
             {
                return Unauthorized(new { message = "User not authenticated." });
             }

             var cart = await _cartService.AddItemToCartAsync(userId, request);
             return Ok(cart);
        }

        [HttpPut("update-item/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> UpdateItem(int cartItemId, [FromBody] int quantity)
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var cart = await _cartService.UpdateCartItemAsync(userId, cartItemId, quantity);
            return Ok(cart);
        }

        [HttpDelete("remove-item/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> RemoveItem(int cartItemId)
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var cart = await _cartService.RemoveItemFromCartAsync(userId, cartItemId);
            return Ok(cart);
        }

        [HttpDelete("clear")]
        public async Task<ActionResult<bool>> ClearCart()
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _cartService.ClearCartAsync(userId);
            return Ok(result);
        }
    }
}
