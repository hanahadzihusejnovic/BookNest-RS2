using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class BookUpdateRequest
    {
        [Required]
        [MaxLength(255)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public int AuthorId { get; set; }

        [Required]
        [MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        public string? CoverImageUrl { get; set; }

        public int? PageCount { get; set; }

        [Required]
        public decimal Price { get; set; }

        [Required]
        public int Stock { get; set; }

        [Required]
        public List<int> CategoryIds { get; set; } = new List<int>();
    }
}
