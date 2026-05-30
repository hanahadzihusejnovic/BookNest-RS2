using AutoMapper;
using BookNest.Model.Enums;
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

        public OrderService(BookNestDbContext dbContext, IMapper mapper, IRabbitMqPublisher publisher) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            _publisher = publisher;
            Stripe.StripeConfiguration.ApiKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
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
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
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
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
                .Include(o => o.Payment)
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
                    oi.Order.Status == OrderStatus.Pending &&
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

            bool isSuccessful;
            string? transactionId = null;

            if (request.PaymentMethod == PaymentMethod.Card)
            {
                if (string.IsNullOrEmpty(request.PaymentIntentId))
                    throw new BusinessException("PaymentIntentId is required for card payments.");

                var service = new Stripe.PaymentIntentService();
                var intent = await service.GetAsync(request.PaymentIntentId, cancellationToken: cancellationToken);

                if (intent.Status != "succeeded")
                    throw new BusinessException($"Payment not completed. Stripe status: {intent.Status}");

                isSuccessful = true;
                transactionId = intent.Id;
            }
            else
            {
                isSuccessful = true;
                transactionId = $"COD-{Guid.NewGuid()}";
            }

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
                    cartItem.Book.Stock -= cartItem.Quantity;
                }

                var payment = new Payment
                {
                    UserId = userId,
                    PaymentMethod = request.PaymentMethod,
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

                return await GetByIdAsync(order.Id, cancellationToken)
                       ?? throw new BusinessException("Failed to retrieve created order.");
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        }

        public async Task<List<OrderResponse>> GetUserOrdersAsync(int userId, CancellationToken cancellationToken = default)
        {
            var orders = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.Shipping)
                    .ThenInclude(s => s.City)
                    .ThenInclude(s => s.Country)
                .Include(o => o.Payment)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                    .ThenInclude(b => b.Author)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync(cancellationToken);

            return _mapper.Map<List<OrderResponse>>(orders);
        }

        private static readonly Dictionary<OrderStatus, List<OrderStatus>> _allowedOrderTransitions = new()
        {
            { OrderStatus.Pending,   new List<OrderStatus> { OrderStatus.Shipped, OrderStatus.Cancelled } },
            { OrderStatus.Shipped,   new List<OrderStatus> { OrderStatus.Delivered, OrderStatus.Cancelled } },
            { OrderStatus.Delivered, new List<OrderStatus>() },
            { OrderStatus.Cancelled, new List<OrderStatus>() },
        };

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (!_allowedOrderTransitions.TryGetValue(order.Status, out var allowed) || !allowed.Contains(request.Status))
                throw new BusinessException($"Cannot transition order from '{order.Status}' to '{request.Status}'.");

            if (request.Status == OrderStatus.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling an order.");

            order.Status = request.Status;
            order.ShippedDate = request.ShippedDate;
            order.StatusChangedAt = DateTime.UtcNow;
            order.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.Status switch
            {
                OrderStatus.Shipped => ("Order has been shipped", $"Your order #{order.Id} is on its way!"),
                OrderStatus.Delivered => ("Order delivered", $"Your order #{order.Id} has been delivered."),
                OrderStatus.Cancelled => ("Order cancelled", $"Your order #{order.Id} has been cancelled. Reason: {request.CancellationReason}"),
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
            catch { }

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

            if (order.Status != OrderStatus.Pending)
                throw new BusinessException("Only pending orders can be cancelled.");

            if (string.IsNullOrWhiteSpace(cancellationReason))
                throw new BusinessException("Cancellation reason is required.");

            foreach (var item in order.OrderItems)
                item.Book.Stock += item.Quantity;

            order.Status = OrderStatus.Cancelled;
            order.StatusChangedAt = DateTime.UtcNow;
            order.StatusChangedByUserId = userId;
            order.CancellationReason = cancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken)
                   ?? throw new BusinessException("Failed to retrieve cancelled order.");
        }

        public async Task<OrderResponse?> UpdateStatusAsync(int id, OrderUpdateRequest request, int changedByUserId, CancellationToken cancellationToken = default)
        {
            var order = await _dbContext.Orders
                .Include(o => o.User)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Book)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
                throw new NotFoundException("Order not found.");

            if (!_allowedOrderTransitions.TryGetValue(order.Status, out var allowed) || !allowed.Contains(request.Status))
                throw new BusinessException($"Cannot transition order from '{order.Status}' to '{request.Status}'.");

            if (request.Status == OrderStatus.Cancelled && string.IsNullOrWhiteSpace(request.CancellationReason))
                throw new BusinessException("Cancellation reason is required when cancelling an order.");

            if (request.Status == OrderStatus.Cancelled)
            {
                foreach (var item in order.OrderItems)
                    item.Book.Stock += item.Quantity;
            }

            order.Status = request.Status;
            if (request.ShippedDate.HasValue)
                order.ShippedDate = request.ShippedDate;
            order.StatusChangedAt = DateTime.UtcNow;
            order.StatusChangedByUserId = changedByUserId;
            order.CancellationReason = request.CancellationReason;

            await _dbContext.SaveChangesAsync(cancellationToken);

            var (title, message) = request.Status switch
            {
                OrderStatus.Shipped => ("Order has been shipped", $"Your order #{order.Id} is on its way!"),
                OrderStatus.Delivered => ("Order delivered", $"Your order #{order.Id} has been delivered."),
                OrderStatus.Cancelled => ("Order cancelled", $"Your order #{order.Id} has been cancelled. Reason: {request.CancellationReason}"),
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
            catch { }

            return await GetByIdAsync(id, cancellationToken);
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(PaymentIntentRequest request)
        {
            var options = new Stripe.PaymentIntentCreateOptions
            {
                Amount = (long)(request.Amount * 100),
                Currency = "bam",
                PaymentMethodTypes = new List<string> { "card" },
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
