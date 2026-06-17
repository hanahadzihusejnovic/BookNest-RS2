using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class ReservationStatusInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
    }
}
