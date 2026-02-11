using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService orderService) : base(orderService)
        {
            _orderService = orderService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<OrderResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost("checkout")]
        public async Task<ActionResult<OrderResponse>> Checkout([FromBody] OrderInsertRequest request)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var order = await _orderService.CreateOrderFromCartAsync(userId, request);
                return Ok(order);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("my-orders")]
        public async Task<ActionResult<List<OrderResponse>>> GetMyOrders()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var orders = await _orderService.GetUserOrdersAsync(userId);
            return Ok(orders);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<OrderResponse?> Update(int id, [FromBody] OrderUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}
