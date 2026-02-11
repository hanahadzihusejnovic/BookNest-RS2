using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
