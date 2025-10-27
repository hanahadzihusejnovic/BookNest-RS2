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
    public class EventReservation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [Required]
        public int EventId { get; set; }

        [ForeignKey(nameof(EventId))]
        public Event Event { get; set; } = null!;

        public Payment Payment { get; set; } = null!;

        public string? TicketQRCodeLink { get; set; }

        [Required]
        public DateTime EventDateTime { get; set; }

        [Required]
        public DateTime ReservationDate { get; set; } = DateTime.UtcNow;

        [Required]
        public int Quantity { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        [Required]
        [Column(TypeName = "nvarchar(20)")]
        public ReservationStatus ReservationStatus { get; set; }
    }
}
