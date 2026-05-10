using BookNest.Model.Enums;

namespace BookNest.Model.Responses
{
    public class TBRListResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int BookId { get; set; }
        public string BookTitle { get; set; } = string.Empty;
        public string BookAuthor { get; set; } = string.Empty;
        public string BookImageUrl { get; set; } = string.Empty;
        public decimal BookPrice { get; set; }
        public ReadingStatus ReadingStatus { get; set; }
        public DateTime AddedAt { get; set; }
    }
}
