namespace BookNest.Model.SearchObjects
{
    public class AuthorSearchObject : BaseSearchObject
    {
        public string? Text { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
    }
}
