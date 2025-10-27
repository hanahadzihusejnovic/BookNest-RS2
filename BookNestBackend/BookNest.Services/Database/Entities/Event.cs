using BookNest.Services.Database.Entities.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Database.Entities
{
    public class Event
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        [Required]
        public int EventCategoryId { get; set; }

        [ForeignKey(nameof(EventCategoryId))]
        public EventCategory EventCategory { get; set; } = null!;

        [Required]
        public int OrganizerId { get; set; }

        [ForeignKey(nameof(OrganizerId))]
        public Organizer Organizer { get; set; } = null!;

        [Required]
        public DateTime EventDate { get; set; }

        [Required]
        public TimeSpan EventTime { get; set; }

        [Required]
        [Column(TypeName = "nvarchar(50)")]
        public EventType EventType { get; set; }
        
        public string? Address { get; set; }
        
        public string? City { get; set; }

        public string? Country { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TicketPrice { get; set; }

        [Required]
        public int Capacity { get; set; }

        [Required]
        public bool IsActive { get; set; } = true;

        public string? ImageUrl { get; set; }

        [Required]
        public int ReservedSeats { get; set; }

        public ICollection<EventReservation> EventReservations { get; set; } = new List<EventReservation>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        
    }
}
