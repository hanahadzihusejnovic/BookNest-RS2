using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Responses
{
    public class OrganizerResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string ContactEmail { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }

        public List<EventResponse> Events { get; set; } = new List<EventResponse>();
    }
}
