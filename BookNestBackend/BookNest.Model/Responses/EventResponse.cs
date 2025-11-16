using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class EventResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int EventCategoryId { get; set; }
        public string EventCategoryName { get; set; } = string.Empty;
        public int OrganizerId { get; set; }
        public string OrganizerName { get; set; } = string.Empty;
        public DateTime EventDate { get; set; }
        public TimeSpan EventTime { get; set; }
        public string EventType { get; set; } = string.Empty; //enum
        public string? Address { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public decimal TicketPrice { get; set; }
        public int Capacity { get; set; }
        public bool IsActive { get; set; }
        public string? ImageUrl { get; set; }
        public int ReservedSeats { get; set; }
    }
}
