using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class CountryInsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
    }
}