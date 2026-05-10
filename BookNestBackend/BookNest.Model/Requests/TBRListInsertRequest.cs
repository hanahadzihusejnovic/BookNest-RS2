using BookNest.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class TBRListInsertRequest
    {
        [Required]
        public int BookId { get; set; }

        [Required]
        public ReadingStatus ReadingStatus { get; set; } = ReadingStatus.ToBeRead;
    }
}
