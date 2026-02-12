using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? BookId { get; set; }
        public int? EventId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
    }
}
