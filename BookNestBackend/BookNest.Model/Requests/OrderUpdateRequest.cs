using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrderUpdateRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "OrderStatusId must be a valid ID.")]
        public int OrderStatusId { get; set; }

        public DateTime? ShippedDate { get; set; }

        [MaxLength(500)]
        public string? CancellationReason { get; set; }
    }
}
