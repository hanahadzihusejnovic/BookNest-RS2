using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrganizerInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string ContactEmail { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }
    }
}
