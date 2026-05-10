using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class CategoryInserRequest
    {
        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;
    }
}
