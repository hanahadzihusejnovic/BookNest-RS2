using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrderUpdateRequest
    {
        [Required]
        public OrderStatus Status { get; set; }

        public DateTime? ShippedDate { get; set; }
    }
}
