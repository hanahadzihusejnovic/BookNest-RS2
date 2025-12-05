using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.SearchObjects
{
    public class BookSearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? Title { get; set; }
        public int? AuthorId { get; set; }
        public string? AuthorName { get; set; }
        public decimal? Price { get; set; }
    }
}
