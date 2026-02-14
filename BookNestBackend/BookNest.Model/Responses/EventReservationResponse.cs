using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class EventReservationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string EventLocation { get; set; } = string.Empty;
        public DateTime EventDateTime { get; set; }
        public DateTime ReservationDate { get; set; }
        public int Quantity { get; set; }
        public decimal TotalPrice { get; set; }
        public ReservationStatus ReservationStatus { get; set; }
        public string? TicketQRCodeLink { get; set; }
        public PaymentResponse Payment { get; set; } = null!;
    }
}
