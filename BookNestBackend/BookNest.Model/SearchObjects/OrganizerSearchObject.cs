namespace BookNest.Model.SearchObjects
{
    public class OrganizerSearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? ContactEmail { get; set; }
    }
}
