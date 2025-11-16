using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class CartUpdateRequest
    {
        [Required]
        public int UserId { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
