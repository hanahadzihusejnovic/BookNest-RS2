using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class EventCategoryUpdateRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;
    }
}
