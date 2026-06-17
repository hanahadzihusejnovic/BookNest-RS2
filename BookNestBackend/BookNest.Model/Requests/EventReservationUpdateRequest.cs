using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class EventReservationUpdateRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "ReservationStatusId must be a valid ID.")]
        public int ReservationStatusId { get; set; }

        [MaxLength(500)]
        public string? CancellationReason { get; set; }
    }
}
