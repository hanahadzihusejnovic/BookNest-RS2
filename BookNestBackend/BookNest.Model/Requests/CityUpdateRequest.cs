using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class CityUpdateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public int CountryId { get; set; }
    }
}