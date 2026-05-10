using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class CartItemInsertRequest
    {
        [Required]
        public int BookId { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }
    }
}
