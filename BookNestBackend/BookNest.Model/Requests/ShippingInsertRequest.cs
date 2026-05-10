using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class ShippingInsertRequest
    {
        [Required]
        [MaxLength(150)]
        public string Address { get; set; } = string.Empty;

        [Required]
        public int CityId { get; set; }

        [Required]
        public int CountryId { get; set; }

        [Required]
        [MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;
    }
}