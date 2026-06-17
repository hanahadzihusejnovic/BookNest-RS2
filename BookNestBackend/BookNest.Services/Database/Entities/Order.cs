using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BookNest.Services.Database.Entities
{
    public class Order
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [Required]
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;

        public DateTime? ShippedDate { get; set; }

        [Required]
        public int OrderStatusId { get; set; }

        [ForeignKey(nameof(OrderStatusId))]
        public OrderStatus OrderStatus { get; set; } = null!;

        public DateTime? StatusChangedAt { get; set; }

        public int? StatusChangedByUserId { get; set; }

        [ForeignKey(nameof(StatusChangedByUserId))]
        public User? StatusChangedByUser { get; set; }

        [MaxLength(500)]
        public string? CancellationReason { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        [Required]
        public int ShippingId { get; set; }

        [ForeignKey(nameof(ShippingId))]
        public Shipping Shipping { get; set; } = null!;

        public Payment Payment { get; set; } = null!;

        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
