using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class PaymentIntentRequest
    {
        public decimal Amount { get; set; }
    }
}