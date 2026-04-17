using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get;set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string FullName => $"{FirstName} {LastName}";
        public string EmailAddress { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public DateTime DateOfBirth { get; set; }
        public string? Address {  get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }

        public List<RoleResponse> Roles { get; set; } = new List<RoleResponse>();

    }
}
