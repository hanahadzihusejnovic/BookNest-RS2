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
using Microsoft.AspNetCore.Mvc;
using BookNest.Services.MessageQueue;
using BookNest.Model.Messages;

namespace BookNest.Services.Services
{
    public class OrderService : BaseCRUDService<OrderResponse, OrderSearchObject, Order, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IRabbitMqPublisher _publisher;

        public OrderService(BookNestDbContext dbContext, IMapper mapper,
            IRabbitMqPublisher publisher) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
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
                    .ThenInclude(b => b.Author)
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

            var mapped = _mapper.Map<List<OrderResponse>>(list);

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
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                return null;
            }

            return _mapper.Map<OrderResponse>(order);
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
                    .ThenInclude(b => b.Author)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<OrderResponse>>(orders);
        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request,
    CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null) return null;

            order.Status = request.Status;
            order.ShippedDate = request.ShippedDate;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.Status switch
            {
                OrderStatus.Processing => ("Order is being processed", $"Your order #{order.Id} is now being processed."),
                OrderStatus.Shipped => ("Order has been shipped", $"Your order #{order.Id} is on its way!"),
                OrderStatus.Delivered => ("Order delivered", $"Your order #{order.Id} has been delivered."),
                OrderStatus.Cancelled => ("Order cancelled", $"Your order #{order.Id} has been cancelled."),
                _ => ("Order updated", $"Your order #{order.Id} status has been updated.")
            };

            await _publisher.PublishAsync("notifications-queue", new NotificationMessage
            {
                UserId = order.UserId,
                Title = title,
                Message = message,
                NotificationType = "OrderStatusChanged",
                SendAt = DateTime.UtcNow
            });

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}
