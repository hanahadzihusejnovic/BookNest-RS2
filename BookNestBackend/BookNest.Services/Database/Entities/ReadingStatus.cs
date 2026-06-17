using System.ComponentModel.DataAnnotations;

namespace BookNest.Services.Database.Entities
{
    public class ReadingStatus
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public ICollection<TBRList> TBRLists { get; set; } = new List<TBRList>();
    }
}
