using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrderInsertRequest
    {
        [Required]
        public ShippingInsertRequest Shipping { get; set; } = null!;

        [Required]
        public PaymentMethod PaymentMethod { get; set; }

        public string? PaymentIntentId { get; set; }
    }
}