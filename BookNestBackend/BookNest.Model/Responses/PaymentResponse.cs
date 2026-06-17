namespace BookNest.Model.Responses
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int PaymentMethodId { get; set; }
        public string PaymentMethodName { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime PaymentDate { get; set; }
        public bool IsSuccessful { get; set; }
        public string? TransactionId { get; set; }
    }
}
