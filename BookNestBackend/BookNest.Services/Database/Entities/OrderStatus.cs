using System.ComponentModel.DataAnnotations;

namespace BookNest.Services.Database.Entities
{
    public class OrderStatus
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public ICollection<Order> Orders { get; set; } = new List<Order>();
    }
}
