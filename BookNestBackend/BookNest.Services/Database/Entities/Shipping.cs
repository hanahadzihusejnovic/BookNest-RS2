using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BookNest.Services.Database.Entities
{
    public class Shipping
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(150)]
        public string Address { get; set; } = string.Empty;

        [Required]
        public int CityId { get; set; }

        [ForeignKey(nameof(CityId))]
        public City City { get; set; } = null!;

        [Required]
        public int CountryId { get; set; }

        [ForeignKey(nameof(CountryId))]
        public Country Country { get; set; } = null!;

        [Required]
        [MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;

        public DateTime? ShippedDate { get; set; }

        public ICollection<Order> Orders { get; set; } = new List<Order>();
    }
}