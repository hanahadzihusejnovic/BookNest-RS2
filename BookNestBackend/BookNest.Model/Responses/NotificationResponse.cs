namespace BookNest.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? BookId { get; set; }
        public int? EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public int NotificationTypeId { get; set; }
        public string NotificationTypeName { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime SendAt { get; set; }
    }
}
