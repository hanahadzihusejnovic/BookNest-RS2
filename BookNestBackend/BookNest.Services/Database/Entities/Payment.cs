using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Database.Entities
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [Required]
        [Column(TypeName = "nvarchar(20)")]
        public PaymentMethod PaymentMethod { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public int? OrderId { get; set; }

        [ForeignKey(nameof(OrderId))]
        public Order? Order { get; set; }

        public int? EventReservationId { get; set; }

        [ForeignKey(nameof(EventReservationId))]
        public EventReservation? EventReservation { get; set; }


        public DateTime PaymentDate { get; set; } = DateTime.UtcNow;

        public bool IsSuccessful { get; set; } = true;

        public string? TransactionId { get; set; }
    }
}
