using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BookNest.Services.Database.Entities
{
    public class TBRList
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [Required]
        public int BookId { get; set; }

        [ForeignKey(nameof(BookId))]
        public Book Book { get; set; } = null!;

        [Required]
        public ReadingStatus ReadingStatus { get; set; } = ReadingStatus.ToBeRead;

        public DateTime AddedAt { get; set; } = DateTime.UtcNow;

    }
}
