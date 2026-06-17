using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class EventInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "EventCategoryId must be a valid ID.")]
        public int EventCategoryId { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "OrganizerId must be a valid ID.")]
        public int OrganizerId { get; set; }

        [Required]
        public DateTime EventDate { get; set; }

        [Required]
        public TimeSpan EventTime { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "EventTypeId must be a valid ID.")]
        public int EventTypeId { get; set; }

        [MaxLength(255)]
        public string? Address { get; set; }
        public int? CityId { get; set; }
        public int? CountryId { get; set; }

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "Ticket price cannot be negative.")]
        public decimal TicketPrice { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Capacity must be at least 1.")]
        public int Capacity { get; set; }

        [Required]
        public bool IsActive { get; set; } = true;

        [MaxLength(500)]
        public string? ImageUrl { get; set; }
    }
}
