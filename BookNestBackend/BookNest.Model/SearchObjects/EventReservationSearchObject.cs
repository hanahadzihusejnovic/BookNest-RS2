namespace BookNest.Model.SearchObjects
{
    public class EventReservationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? EventId { get; set; }
        public int? ReservationStatusId { get; set; }
        public DateTime? ReservationDateFrom { get; set; }
        public DateTime? ReservationDateTo { get; set; }
    }
}
