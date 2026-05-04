using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Messages
{
    public class NotificationMessage
    {
        public int UserId { get; set; }
        public int? BookId { get; set; }
        public int? EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string NotificationType { get; set; } = string.Empty;
        public DateTime SendAt { get; set; } = DateTime.UtcNow;
    }
}