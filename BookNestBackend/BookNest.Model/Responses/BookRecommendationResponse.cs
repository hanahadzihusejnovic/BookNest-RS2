namespace BookNest.Model.Responses
{
    public class BookRecommendationResponse
    {
        public BookResponse Book { get; set; } = null!;
        public string Reason { get; set; } = string.Empty;
    }
}