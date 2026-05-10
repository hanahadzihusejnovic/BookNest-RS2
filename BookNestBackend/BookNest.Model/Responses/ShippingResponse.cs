namespace BookNest.Model.Responses
{
    public class ShippingResponse
    {
        public int Id { get; set; }
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        public int CountryId { get; set; }
        public string CountryName { get; set; } = string.Empty;
        public string PostalCode { get; set; } = string.Empty;
        public DateTime? ShippedDate { get; set; }
    }
}
