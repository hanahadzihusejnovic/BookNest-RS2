using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class OrderUpdateRequest
    {
        [Required]
        public OrderStatus Status { get; set; }

        public DateTime? ShippedDate { get; set; }
    }
}
