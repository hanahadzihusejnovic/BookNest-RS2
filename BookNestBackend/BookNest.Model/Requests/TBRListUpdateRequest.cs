using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class TBRListUpdateRequest
    {
        [Required]
        public ReadingStatus ReadingStatus { get; set; }
    }
}
