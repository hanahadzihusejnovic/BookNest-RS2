namespace BookNest.Model.Responses
{
    public class EventCategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        public List<EventResponse> Events { get; set; } = new List<EventResponse>();
    }
}
