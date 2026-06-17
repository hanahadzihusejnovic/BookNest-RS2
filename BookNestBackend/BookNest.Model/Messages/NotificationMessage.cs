using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Messages
{
    public class NotificationMessage
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "UserId must be a valid positive integer.")]
        public int UserId { get; set; }

        public int? BookId { get; set; }
        public int? EventId { get; set; }

        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Message { get; set; } = string.Empty;

        [Required]
        public string NotificationType { get; set; } = string.Empty;

        public DateTime SendAt { get; set; } = DateTime.UtcNow;
    }
}