using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BookNest.Services.Database.Entities
{
    public class City
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public int CountryId { get; set; }

        [ForeignKey(nameof(CountryId))]
        public Country Country { get; set; } = null!;

        public ICollection<User> Users { get; set; } = new List<User>();
        public ICollection<Shipping> Shippings { get; set; } = new List<Shipping>();
        public ICollection<Event> Events { get; set; } = new List<Event>();
    }
}