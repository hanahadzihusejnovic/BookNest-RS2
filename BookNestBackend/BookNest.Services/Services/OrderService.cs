using AutoMapper;
using BookNest.Model.Constants;
using Microsoft.Extensions.Logging;
using BookNest.Model.Exceptions;
using BookNest.Model.Messages;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using BookNest.Services.MessageQueue;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class OrderService : BaseCRUDService<OrderResponse, OrderSearchObject, Order, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        private readonly BookNestDbContext _dbContext;
        private readonly IRabbitMqPublisher _publisher;
        private readonly ILogger<OrderService> _logger;

        public OrderService(BookNestDbContext dbContext, IMapper mapper, IRabbitMqPublisher publisher, ILogger<OrderService> logger) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
            _logger = logger;
            Stripe.StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            if (search.UserId.HasValue)
            {
                query = query.Where(o => o.UserId == search.UserId.Value);
            }

            if (search.OrderStatusId.HasValue)
            {
                query = query.Where(o => o.OrderStatusId == search.OrderStatusId.Value);
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
                .Include(o => o.OrderStatus)
                .Include(o => o.Shipping)
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
                .Include(o => o.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                    .ThenInclude(b => b.Author)
                .AsQueryable();

            query = ApplyFilter(query, search);

            query = query.OrderByDescending(o => o.OrderDate).ThenByDescending(o => o.Id);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync(cancellationToken);
            }

            if (search.RetrieveAll)
            {
                query = query.Take(500);
            }
            else
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
                .Include(o => o.OrderStatus)
                .Include(o => o.Shipping)
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
                .Include(o => o.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                    .ThenInclude(b => b.Author)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
            {
                throw new NotFoundException("Order not found.");
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
                throw new BusinessException("Cart is empty or does not exist.");

            var cartBookIds = cart.CartItems.Select(ci => ci.BookId).ToHashSet();

            var alreadyPaid = await _dbContext.OrderItems
                .Include(oi => oi.Order)
                    .ThenInclude(o => o.Payment)
                .Where(oi =>
                    oi.Order.UserId == userId &&
                    oi.Order.OrderStatusId == OrderStatuses.Pending &&
                    oi.Order.Payment != null &&
                    oi.Order.Payment.IsSuccessful &&
                    cartBookIds.Contains(oi.BookId))
                .AnyAsync(cancellationToken);

            if (alreadyPaid)
                throw new BusinessException("Some items in your cart have already been paid for.");

            foreach (var cartItem in cart.CartItems)
            {
                if (cartItem.Book.Stock < cartItem.Quantity)
                    throw new BusinessException($"Not enough stock for '{cartItem.Book.Title}'. Available: {cartItem.Book.Stock}.");
            }

            decimal totalPrice = cart.CartItems.Sum(ci => ci.Price * ci.Quantity);

            var city = await _dbContext.Cities.FindAsync(new object[] { request.Shipping.CityId }, cancellationToken);
            if (city == null)
                throw new BusinessException("Selected city does not exist.");

            if (city.CountryId != request.Shipping.CountryId)
                throw new BusinessException("Selected city does not belong to the selected country.");

            bool isSuccessful;
            string? transactionId = null;

            if (request.PaymentMethodId == PaymentMethods.Card)
            {
                if (string.IsNullOrEmpty(request.PaymentIntentId))
                    throw new BusinessException("PaymentIntentId is required for card payments.");

                var service = new Stripe.PaymentIntentService();
                var intent = await service.GetAsync(request.PaymentIntentId, cancellationToken: cancellationToken);

                if (intent.Status != "succeeded")
                    throw new BusinessException($"Payment not completed. Stripe status: {intent.Status}");

                if (intent.Amount != (long)(totalPrice * 100))
                    throw new BusinessException("Payment amount does not match order total.");

                if (intent.Currency != "bam")
                    throw new BusinessException("Invalid payment currency.");

                var alreadyUsedIntent = await _dbContext.Payments
                    .AnyAsync(p => p.TransactionId == intent.Id, cancellationToken);
                if (alreadyUsedIntent)
                    throw new BusinessException("This payment has already been used.");

                if (intent.Metadata.TryGetValue("userId", out var metaUserId) && metaUserId != userId.ToString())
                    throw new BusinessException("Payment does not belong to this user.");

                isSuccessful = true;
                transactionId = intent.Id;
            }
            else
            {
                isSuccessful = true;
                transactionId = $"COD-{Guid.NewGuid()}";
            }

            Order order;
            using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var shipping = new Shipping
                {
                    Address = request.Shipping.Address,
                    CityId = request.Shipping.CityId,
                    CountryId = request.Shipping.CountryId,
                    PostalCode = request.Shipping.PostalCode
                };

                _dbContext.Shippings.Add(shipping);
                await _dbContext.SaveChangesAsync(cancellationToken);

                order = new Order
                {
                    UserId = userId,
                    OrderDate = DateTime.UtcNow,
                    OrderStatusId = OrderStatuses.Pending,
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
                    cartItem.Book.Stock -= cartItem.Quantity;
                }

                var payment = new Payment
                {
                    UserId = userId,
                    PaymentMethodId = request.PaymentMethodId,
                    Amount = totalPrice,
                    OrderId = order.Id,
                    PaymentDate = DateTime.UtcNow,
                    IsSuccessful = isSuccessful,
                    TransactionId = transactionId
                };

                _dbContext.Payments.Add(payment);
                _dbContext.CartItems.RemoveRange(cart.CartItems);

                await _dbContext.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }

            try
            {
                var username = (await _dbContext.Users.FindAsync(new object[] { userId }, cancellationToken))?.Username ?? $"#{userId}";
                var adminUserIds = await GetAdminUserIdsAsync(cancellationToken);
                foreach (var adminId in adminUserIds)
                {
                    await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                    {
                        UserId = adminId,
                        Title = "New order placed",
                        Message = $"User {username} placed a new order #{order.Id} for {totalPrice:F2} BAM.",
                        NotificationType = "NewOrder",
                        SendAt = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish new-order notification for order {OrderId}", order.Id);
            }

            return await GetByIdAsync(order.Id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve created order.");
        }

        private async Task<List<int>> GetAdminUserIdsAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.UserRoles
                .Where(ur => ur.Role.Name == Roles.Admin)
                .Select(ur => ur.UserId)
                .Distinct()
                .ToListAsync(cancellationToken);
        }

        public async Task<List<OrderResponse>> GetUserOrdersAsync(int userId, CancellationToken cancellationToken = default)
        {
            var orders = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.OrderStatus)
                .Include(o => o.Shipping)
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
                .Include(o => o.Payment)
                    .ThenInclude(p => p.PaymentMethod)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                    .ThenInclude(b => b.Author)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<OrderResponse>>(orders);
        }

        private static readonly Dictionary<int, List<int>> _allowedOrderTransitions = new()
        {
            { OrderStatuses.Pending,   new List<int> { OrderStatuses.Shipped, OrderStatuses.Cancelled } },
            { OrderStatuses.Shipped,   new List<int> { OrderStatuses.Delivered, OrderStatuses.Cancelled } },
            { OrderStatuses.Delivered, new List<int>() },
            { OrderStatuses.Cancelled, new List<int>() },
        };

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.OrderStatus)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (!_allowedOrderTransitions.TryGetValue(order.OrderStatusId, out var allowed) || !allowed.Contains(request.OrderStatusId))
                throw new BusinessException($"Cannot transition order from '{order.OrderStatus?.Name}' to status ID {request.OrderStatusId}.");

            if (request.OrderStatusId == OrderStatuses.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling an order.");

            order.OrderStatusId = request.OrderStatusId;
            order.ShippedDate = request.ShippedDate;
            order.StatusChangedAt = DateTime.UtcNow;
            order.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.OrderStatusId switch
            {
                OrderStatuses.Shipped => ("Order has been shipped", $"Your order #{order.Id} is on its way!"),
                OrderStatuses.Delivered => ("Order delivered", $"Your order #{order.Id} has been delivered."),
                OrderStatuses.Cancelled => ("Order cancelled", $"Your order #{order.Id} has been cancelled. Reason: {request.CancellationReason}"),
                _ => ("Order updated", $"Your order #{order.Id} status has been updated.")
            };

            try
            {
                await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                {
                    UserId = order.UserId,
                    Title = title,
                    Message = message,
                    NotificationType = "OrderStatusChanged",
                    SendAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish notification for order {OrderId}", order.Id);
            }

            return await GetByIdAsync(id, cancellationToken);
        }

        public async Task<OrderResponse> CancelUserOrderAsync(int id, int userId, string cancellationReason, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null || order.UserId != userId)
                throw new NotFoundException("Order not found.");

            if (order.OrderStatusId != OrderStatuses.Pending)
                throw new BusinessException("Only pending orders can be cancelled.");

            if (string.IsNullOrWhiteSpace(cancellationReason))
                throw new BusinessException("Cancellation reason is required.");

            foreach (var item in order.OrderItems)
                item.Book.Stock += item.Quantity;

            order.OrderStatusId = OrderStatuses.Cancelled;
            order.StatusChangedAt = DateTime.UtcNow;
            order.StatusChangedByUserId = userId;
            order.CancellationReason = cancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            try
            {
                var adminUserIds = await GetAdminUserIdsAsync(cancellationToken);
                foreach (var adminId in adminUserIds)
                {
                    await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                    {
                        UserId = adminId,
                        Title = "Order cancelled by user",
                        Message = $"User {order.User.Username} cancelled order #{order.Id}. Reason: {cancellationReason}",
                        NotificationType = "OrderCancelledByUser",
                        SendAt = DateTime.UtcNow
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish order-cancelled-by-user notification for order {OrderId}", order.Id);
            }

            return await GetByIdAsync(id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve cancelled order.");
        }

        public async Task<OrderResponse?> UpdateStatusAsync(int id, OrderUpdateRequest request, int changedByUserId, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.OrderStatus)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (!_allowedOrderTransitions.TryGetValue(order.OrderStatusId, out var allowed) || !allowed.Contains(request.OrderStatusId))
                throw new BusinessException($"Cannot transition order from '{order.OrderStatus?.Name}' to status ID {request.OrderStatusId}.");

            if (request.OrderStatusId == OrderStatuses.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling an order.");

            if (request.OrderStatusId == OrderStatuses.Cancelled)
            {
                foreach (var item in order.OrderItems)
                    item.Book.Stock += item.Quantity;
            }

            order.OrderStatusId = request.OrderStatusId;
            if (request.ShippedDate.HasValue)
                order.ShippedDate = request.ShippedDate;
            order.StatusChangedAt = DateTime.UtcNow;
            order.StatusChangedByUserId = changedByUserId;
            order.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.OrderStatusId switch
            {
                OrderStatuses.Shipped => ("Order has been shipped", $"Your order #{order.Id} is on its way!"),
                OrderStatuses.Delivered => ("Order delivered", $"Your order #{order.Id} has been delivered."),
                OrderStatuses.Cancelled => ("Order cancelled", $"Your order #{order.Id} has been cancelled. Reason: {request.CancellationReason}"),
                _ => ("Order updated", $"Your order #{order.Id} status has been updated.")
            };

            try
            {
                await _publisher.PublishAsync("notifications-queue", new NotificationMessage
                {
                    UserId = order.UserId,
                    Title = title,
                    Message = message,
                    NotificationType = "OrderStatusChanged",
                    SendAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish notification for order {OrderId}", order.Id);
            }

            return await GetByIdAsync(id, cancellationToken);
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(int userId)
        {
            var cart = await _dbContext.Carts
                .Include(c => c.CartItems)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null || !cart.CartItems.Any())
                throw new BusinessException("Cart is empty.");

            decimal total = cart.CartItems.Sum(ci => ci.Price * ci.Quantity);

            var options = new Stripe.PaymentIntentCreateOptions
            {
                Amount = (long)(total * 100),
                Currency = "bam",
                PaymentMethodTypes = new List<string> { "card" },
                Metadata = new Dictionary<string, string>
                {
                    { "userId", userId.ToString() }
                }
            };

            var service = new Stripe.PaymentIntentService();
            var intent = await service.CreateAsync(options);

            return new PaymentIntentResponse
            {
                ClientSecret = intent.ClientSecret,
                PaymentIntentId = intent.Id
            };
        }
    }
}
