using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class EventReservationInsertRequest
    {
        [Required]
        public int EventId { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }

        [Required]
        public PaymentMethod PaymentMethod { get; set; }

        public string? TransactionId { get; set; }
    }
}
