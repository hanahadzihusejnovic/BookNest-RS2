namespace BookNest.Model.Responses
{
    public class TicketValidationResponse
    {
        public bool IsValid { get; set; }
        public string Message { get; set; } = string.Empty;
        public int? ReservationId { get; set; }
        public string? EventName { get; set; }
        public DateTime? EventDate { get; set; }
        public TimeSpan? EventTime { get; set; }
        public int? Quantity { get; set; }
        public string? ReservationStatus { get; set; }
        public string? UserFullName { get; set; }
    }
}
