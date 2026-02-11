using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class OrderInsertRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public ShippingInsertRequest Shipping { get; set; } = null!;

        [Required]
        public PaymentMethod PaymentMethod { get; set; }

        public string? TransactionId { get; set; }
    }
}
