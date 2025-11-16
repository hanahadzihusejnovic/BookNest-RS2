using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BookNest.Model.Enums;
using System.Text.Json.Serialization;

namespace BookNest.Model.Requests
{
    public class EventInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        [Required]
        public int EventCategoryId { get; set; }

        [Required]
        public int OrganizerId { get; set; }

        [Required]
        public DateTime EventDate { get; set; }

        [Required]
        public TimeSpan EventTime { get; set; }

        [Required]
        public EventType EventType { get; set; }

        public string? Address { get; set; }

        public string? City { get; set; }

        public string? Country { get; set; }

        [Required]
        public decimal TicketPrice { get; set; }

        [Required]
        public int Capacity { get; set; }

        [Required]
        public bool IsActive { get; set; } = true;

        public string? ImageUrl { get; set; }

        [Required]
        public int ReservedSeats { get; set; }
    }
}
