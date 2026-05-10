using System.ComponentModel.DataAnnotations;

namespace BookNest.Services.Database.Entities
{
    public class Country
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public ICollection<City> Cities { get; set; } = new List<City>();
        public ICollection<User> Users { get; set; } = new List<User>();
        public ICollection<Shipping> Shippings { get; set; } = new List<Shipping>();
        public ICollection<Event> Events { get; set; } = new List<Event>();
    }
}