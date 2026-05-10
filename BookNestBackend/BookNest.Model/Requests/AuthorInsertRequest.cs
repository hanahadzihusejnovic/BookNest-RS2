using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class AuthorInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        public DateTime DateOfBirth { get; set; }

        public DateTime? DateOfDeath { get; set; }

        [Required]
        [MaxLength(500)]
        public string Biography { get; set; } = string.Empty;

        public string? ImageUrl {  get; set; }
    }
}
