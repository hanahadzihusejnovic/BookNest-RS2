using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.SearchObjects
{
    public class CategorySearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? Name { get; set; }
    }
}
