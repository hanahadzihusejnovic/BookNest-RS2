using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class ReadingStatusInsertRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
    }
}
