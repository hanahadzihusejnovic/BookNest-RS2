using System.ComponentModel.DataAnnotations;

namespace BookNest.Services.Database.Entities
{
    public class ReservationStatus
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public ICollection<EventReservation> EventReservations { get; set; } = new List<EventReservation>();
    }
}
