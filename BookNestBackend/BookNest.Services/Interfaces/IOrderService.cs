using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;

namespace BookNest.Services.Interfaces
{
    public interface IOrderService : IBaseCRUDService<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        Task<OrderResponse> CreateOrderFromCartAsync(int userId, OrderInsertRequest request, CancellationToken cancellationToken = default);
        Task<List<OrderResponse>> GetUserOrdersAsync(int userId, CancellationToken cancellationToken = default);
        Task<PaymentIntentResponse> CreatePaymentIntentAsync(PaymentIntentRequest request);
        Task<OrderResponse> CancelUserOrderAsync(int id, int userId, string cancellationReason, CancellationToken cancellationToken = default);
        Task<OrderResponse?> UpdateStatusAsync(int id, OrderUpdateRequest request, int changedByUserId, CancellationToken cancellationToken = default);
    }
}
