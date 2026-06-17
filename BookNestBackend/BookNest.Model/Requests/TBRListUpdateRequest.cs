using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class TBRListUpdateRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "ReadingStatusId must be a valid ID.")]
        public int ReadingStatusId { get; set; }
    }
}
