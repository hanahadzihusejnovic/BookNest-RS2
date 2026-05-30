using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class EventReservationUpdateRequest
    {
        [Required]
        public ReservationStatus ReservationStatus { get; set; }

        [MaxLength(500)]
        public string? CancellationReason { get; set; }
    }
}
