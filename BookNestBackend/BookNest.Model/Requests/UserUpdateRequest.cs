using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class UserUpdateRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [EmailAddress]
        public string EmailAddress { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        public string? Password { get; set; }

        [Required]
        public DateTime DateOfBirth { get; set; }

        public string? Address { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ImageUrl { get; set; }

        [Required]
        public List<int> RoleIds { get; set; } = new List<int>();
    }
}
