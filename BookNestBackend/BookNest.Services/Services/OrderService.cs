using AutoMapper;
using BookNest.Model.Enums;
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
    public class OrderService : BaseCRUDService<OrderResponse, OrderSearchObject, Order, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        private readonly BookNestDbContext _dbContext;

        public OrderService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(o => o.UserId == search.UserId.Value);
            }

            if (search.Status.HasValue)
            {
                query = query.Where(o => o.Status == search.Status.Value);
            }

            if (search.OrderDateFrom.HasValue)
            {
                query = query.Where(o => o.OrderDate >= search.OrderDateFrom.Value);
            }

            if (search.OrderDateTo.HasValue)
            {
                query = query.Where(o => o.OrderDate <= search.OrderDateTo.Value);
            }

            return query;
        }

        public override async Task<PagedResult<OrderResponse>> GetAsync(OrderSearchObject search, CancellationToken cancellationToken)
        {
            var query = _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Shipping)
                .Include(o => o.Payment)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .AsQueryable();

            query = ApplyFilter(query, search);

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

            var mapped = list.Select(MapToOrderResponse).ToList();

            return new PagedResult<OrderResponse>
            {
                Items = mapped,
                TotalCount = totalCount
            };
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Shipping)
                .Include(o => o.Payment)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                return null;
            }

            return MapToOrderResponse(order);
        }

        public async Task<OrderResponse> CreateOrderFromCartAsync(int userId, OrderInsertRequest request, CancellationToken cancellationToken = default)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                    .ThenInclude(ci => ci.Book)
                .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

            if (cart == null || !cart.CartItems.Any())
            {
                throw new Exception("Cart is empty or does not exist.");
            }

            decimal totalPrice = cart.CartItems.Sum(ci => ci.Price * ci.Quantity);

            var shipping = new Shipping
            {
                Address = request.Shipping.Address,
                City = request.Shipping.City,
                Country = request.Shipping.Country,
                PostalCode = request.Shipping.PostalCode
            };

            _dbContext.Shippings.Add(shipping);
            await _dbContext.SaveChangesAsync(cancellationToken);

            var order = new Order
            {
                UserId = userId,
                OrderDate = DateTime.UtcNow,
                Status = OrderStatus.Pending,
                TotalPrice = totalPrice,
                ShippingId = shipping.Id
            };

            _dbContext.Orders.Add(order);
            await _dbContext.SaveChangesAsync(cancellationToken);

            foreach (var cartItem in cart.CartItems)
            {
                var orderItem = new OrderItem
                {
                    OrderId = order.Id,
                    BookId = cartItem.BookId,
                    Quantity = cartItem.Quantity,
                    Price = cartItem.Price
                };

                _dbContext.OrderItems.Add(orderItem);
            }

            var payment = new Payment
            {
                UserId = userId,
                PaymentMethod = request.PaymentMethod,
                Amount = totalPrice,
                OrderId = order.Id,
                PaymentDate = DateTime.UtcNow,
                IsSuccessful = true,
                TransactionId = request.TransactionId
            };

            _dbContext.Payments.Add(payment);

            _dbContext.CartItems.RemoveRange(cart.CartItems);

            await _dbContext.SaveChangesAsync(cancellationToken);
            
            return await GetByIdAsync(order.Id, cancellationToken)
                   ?? throw new Exception("Failed to retrieve created order.");
        }

        public async Task<List<OrderResponse>> GetUserOrdersAsync(int userId, CancellationToken cancellationToken = default)
        {
            var orders = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Shipping)
                .Include(o => o.Payment)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);

            return orders.Select(MapToOrderResponse).ToList();
        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders.FindAsync(new object[] { id }, cancellationToken);

            if (order == null)
            {
                return null;
            }

            order.Status = request.Status;
            order.ShippedDate = request.ShippedDate;

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken);
        }

        private OrderResponse MapToOrderResponse(Order order)
        {
            return new OrderResponse
            {
                Id = order.Id,
                UserId = order.UserId,
                UserFullName = $"{order.User.FirstName} {order.User.LastName}",
                OrderDate = order.OrderDate,
                ShippedDate = order.ShippedDate,
                Status = order.Status,
                TotalPrice = order.TotalPrice,
                Shipping = new ShippingResponse
                {
                    Id = order.Shipping.Id,
                    Address = order.Shipping.Address,
                    City = order.Shipping.City,
                    Country = order.Shipping.Country,
                    PostalCode = order.Shipping.PostalCode,
                    ShippedDate = order.Shipping.ShippedDate
                },
                Payment = new PaymentResponse
                {
                    Id = order.Payment.Id,
                    PaymentMethod = order.Payment.PaymentMethod,
                    Amount = order.Payment.Amount,
                    PaymentDate = order.Payment.PaymentDate,
                    IsSuccessful = order.Payment.IsSuccessful,
                    TransactionId = order.Payment.TransactionId
                },
                OrderItems = order.OrderItems.Select(oi => new OrderItemResponse
                {
                    Id = oi.Id,
                    BookId = oi.BookId,
                    BookTitle = oi.Book.Title,
                    Quantity = oi.Quantity,
                    Price = oi.Price
                }).ToList()
            };
        }
    }
}
