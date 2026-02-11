using BookNest.API.BaseControllers;
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

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<CartResponse>> Get([FromQuery] BaseSearchObject search)
        {
            return await base.Get(search);
        }

        [HttpGet("my-cart")]
        public async Task<ActionResult<CartResponse>> GetMyCart()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

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
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var cart = await _cartService.AddItemToCartAsync(userId, request);
                return Ok(cart);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("update-item/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> UpdateItem(int cartItemId, [FromBody] int quantity)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var cart = await _cartService.UpdateCartItemAsync(userId, cartItemId, quantity);
                return Ok(cart);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("remove-item/{cartItemId}")]
        public async Task<ActionResult<CartResponse>> RemoveItem(int cartItemId)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var cart = await _cartService.RemoveItemFromCartAsync(userId, cartItemId);
                return Ok(cart);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("clear")]
        public async Task<ActionResult<bool>> ClearCart()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _cartService.ClearCartAsync(userId);
            return Ok(result);
        }
    }
}
