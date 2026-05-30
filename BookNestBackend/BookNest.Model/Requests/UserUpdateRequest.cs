using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class UserUpdateRequest
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email address is required.")]
        [MaxLength(50)]
        [EmailAddress(ErrorMessage = "Enter a valid email address.")]
        public string EmailAddress { get; set; } = string.Empty;

        [Required(ErrorMessage = "Username is required.")]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? Password { get; set; }

        [Required(ErrorMessage = "Date of birth is required.")]
        public DateTime DateOfBirth { get; set; }

        [MaxLength(255)]
        public string? Address { get; set; }
        public int? CityId { get; set; }
        public int? CountryId { get; set; }
        [MaxLength(20)]
        [RegularExpression(@"^\+?[0-9\s\-\(\)]{7,20}$", ErrorMessage = "Enter a valid phone number (e.g. +387 61 234 567).")]
        public string? PhoneNumber { get; set; }
        [MaxLength(500)]
        public string? ImageUrl { get; set; }
    }
}
