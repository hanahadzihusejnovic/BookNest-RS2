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
