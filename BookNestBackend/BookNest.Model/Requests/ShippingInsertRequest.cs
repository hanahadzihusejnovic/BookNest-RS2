using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class ShippingInsertRequest
    {
        [Required]
        [MaxLength(150)]
        public string Address { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string City { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Country { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;
    }
}
