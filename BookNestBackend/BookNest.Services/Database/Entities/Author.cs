using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Database.Entities
{
    public class Author
    {
        [Key]
        public int Id { get; set; }

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

        public string? ImageUrl { get; set; }
        
        public ICollection<Book> Books { get; set; } = new List<Book>();

    }
}
