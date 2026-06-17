using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrderInsertRequest
    {
        [Required]
        public ShippingInsertRequest Shipping { get; set; } = null!;

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "PaymentMethodId must be a valid ID.")]
        public int PaymentMethodId { get; set; }

        public string? PaymentIntentId { get; set; }
    }
}
