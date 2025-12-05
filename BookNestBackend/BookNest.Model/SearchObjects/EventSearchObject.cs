using BookNest.Model.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.SearchObjects
{
    public class EventSearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? Name { get; set; }
        public int? EventCategoryId { get; set; }
        public string? CategoryName { get; set; }
        public int? OrganizerId { get; set; }
        public string? OrganizerName { get; set; }
        public EventType? EventType { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public bool? IsActive { get; set; }
    }
}
