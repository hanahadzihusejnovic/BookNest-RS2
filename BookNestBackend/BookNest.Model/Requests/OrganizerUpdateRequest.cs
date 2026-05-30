using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class OrganizerUpdateRequest
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Contact email is required.")]
        [MaxLength(50)]
        [EmailAddress(ErrorMessage = "Enter a valid email address.")]
        public string ContactEmail { get; set; } = string.Empty;

        [MaxLength(20)]
        [RegularExpression(@"^\+?[0-9\s\-\(\)]{7,20}$", ErrorMessage = "Enter a valid phone number (e.g. +387 61 234 567).")]
        public string? PhoneNumber { get; set; }
    }
}
