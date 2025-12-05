using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Username { get; set; }
        public bool? IsActive { get; set; }
        public string? EmailAddress { get; set; }
    }
}
