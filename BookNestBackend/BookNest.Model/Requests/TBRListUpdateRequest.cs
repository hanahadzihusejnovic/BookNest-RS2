using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Requests
{
    public class TBRListUpdateRequest
    {
        [Required]
        public ReadingStatus ReadingStatus { get; set; }
    }
}
