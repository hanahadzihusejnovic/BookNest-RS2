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
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        public int? BookId { get; set; }

        public Book? Book { get; set; }

        public int? EventId {  get; set; }

        public Event? Event { get; set; }

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        [Required]
        public bool IsRead { get; set; }

        [Required]
        public DateTime SendAt { get; set; } = DateTime.UtcNow;

        [Required]
        public NotificationType NotificationType { get; set; }
    }
}
