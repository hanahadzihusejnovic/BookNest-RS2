namespace BookNest.Model.Responses
{
    public class EventRecommendationResponse
    {
        public EventResponse Event { get; set; } = null!;
        public string Reason { get; set; } = string.Empty;
    }
}