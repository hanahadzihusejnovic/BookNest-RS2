using BookNest.Model.Enums;

namespace BookNest.Model.SearchObjects
{
    public class EventReservationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? EventId { get; set; }
        public ReservationStatus? ReservationStatus { get; set; }
        public DateTime? ReservationDateFrom { get; set; }
        public DateTime? ReservationDateTo { get; set; }
    }
}
