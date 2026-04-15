using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Stripe;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        private readonly IOrderService _orderService;
        private readonly IConfiguration _configuration;

        public OrderController(IOrderService orderService, IConfiguration configuration) : base(orderService)
        {
            _orderService = orderService;
            _configuration = configuration;
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

        [ApiExplorerSettings(IgnoreApi = true)]
        public override Task<OrderResponse> Create([FromBody] OrderInsertRequest request)
        {
            throw new NotSupportedException("Use POST /api/Order/checkout instead.");
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

        [HttpPost("create-payment-intent")]
        public async Task<ActionResult> CreatePaymentIntent([FromBody] PaymentIntentRequest request)
        {
            try
            {
                StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];

                var options = new PaymentIntentCreateOptions
                {
                    Amount = (long)(request.Amount * 100),
                    Currency = "bam",
                    PaymentMethodTypes = new List<string> { "card" },
                };

                var service = new PaymentIntentService();
                var intent = await service.CreateAsync(options);

                return Ok(new
                {
                    clientSecret = intent.ClientSecret,
                    paymentIntentId = intent.Id
                });
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
