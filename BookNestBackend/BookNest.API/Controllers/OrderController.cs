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
    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService orderService) : base(orderService)
        {
            _orderService = orderService;
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<PagedResult<OrderResponse>> Get([FromQuery] OrderSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<OrderResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [ApiExplorerSettings(IgnoreApi = true)]
        public override Task<OrderResponse> Create([FromBody] OrderInsertRequest request)
        {
            throw new NotSupportedException("Use POST /api/Order/checkout instead.");
        }

        [HttpPost("checkout")]
        public async Task<ActionResult<OrderResponse>> Checkout([FromBody] OrderInsertRequest request)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) 
                return Unauthorized(new { message = "User not authenticated." });

            var order = await _orderService.CreateOrderFromCartAsync(userId, request);
            return Ok(order);
        }

        [HttpPost("create-payment-intent")]
        public async Task<ActionResult> CreatePaymentIntent([FromBody] PaymentIntentRequest request)
        {
            var result = await _orderService.CreatePaymentIntentAsync(request);
            return Ok(result);
        }

        [HttpGet("my-orders")]
        public async Task<ActionResult<List<OrderResponse>>> GetMyOrders()
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized(new { message = "User not authenticated." });

            var orders = await _orderService.GetUserOrdersAsync(userId);
            return Ok(orders);
        }

        [HttpPost("{id}/cancel")]
        public async Task<ActionResult<OrderResponse>> CancelOrder(int id, [FromBody] string cancellationReason)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();

            var result = await _orderService.CancelUserOrderAsync(id, userId, cancellationReason);
            return Ok(result);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<OrderResponse?> Update(int id, [FromBody] OrderUpdateRequest request)
        {
            var adminId = GetCurrentUserId();
            return await _orderService.UpdateStatusAsync(id, request, adminId);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}
