namespace BookNest.Model.Responses
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string? UserEmail { get; set; }
        public string? UserPhoneNumber { get; set; }
        public DateTime OrderDate { get; set; }
        public DateTime? ShippedDate { get; set; }
        public int OrderStatusId { get; set; }
        public string OrderStatusName { get; set; } = string.Empty;
        public DateTime? StatusChangedAt { get; set; }
        public string? CancellationReason { get; set; }
        public decimal TotalPrice { get; set; }
        public ShippingResponse Shipping { get; set; } = null!;
        public PaymentResponse Payment { get; set; } = null!;
        public List<OrderItemResponse> OrderItems { get; set; } = new List<OrderItemResponse>();
    }
}
