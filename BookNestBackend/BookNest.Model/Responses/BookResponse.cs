using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class BookResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public int AuthorId { get; set; }
        public string AuthorName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime? PublicationDate { get; set; }
        public string? CoverImageUrl { get; set; }
        public int? PageCount { get; set; }
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public string? AuthorBiography { get; set; }
        public string? AuthorImageUrl { get; set; }
        public double? AverageRating { get; set; }
        public int ReviewCount { get; set; }
        public List<ReviewResponse> Reviews { get; set; } = new List<ReviewResponse>();
        public List<CategoryResponse> Categories { get; set; } = new List<CategoryResponse>();
    }
}
