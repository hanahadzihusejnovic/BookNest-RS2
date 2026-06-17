using System.ComponentModel.DataAnnotations;

namespace BookNest.Services.Database.Entities
{
    public class NotificationType
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
