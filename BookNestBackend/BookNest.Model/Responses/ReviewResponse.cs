using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public int? BookId { get; set; }
        public string? BookTitle { get; set; }
        public int? EventId { get; set; }
        public string? EventTitle { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
