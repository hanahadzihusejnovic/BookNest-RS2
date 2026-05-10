using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class CartUpdateRequest
    {
        [Required]
        public int UserId { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
