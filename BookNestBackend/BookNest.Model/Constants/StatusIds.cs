namespace BookNest.Model.Constants
{
    public static class ReservationStatuses
    {
        public const int Pending = 1;
        public const int Confirmed = 2;
        public const int Cancelled = 3;
    }

    public static class OrderStatuses
    {
        public const int Pending = 1;
        public const int Shipped = 2;
        public const int Delivered = 3;
        public const int Cancelled = 4;
    }

    public static class PaymentMethods
    {
        public const int CashOnDelivery = 1;
        public const int Card = 2;
    }

    public static class EventTypes
    {
        public const int Online = 1;
        public const int InPerson = 2;
    }

    public static class ReadingStatuses
    {
        public const int ToBeRead = 1;
        public const int Reading = 2;
        public const int Read = 3;
    }

    public static class NotificationTypes
    {
        public const int OrderStatusChanged = 1;
        public const int ReservationStatusChanged = 2;
        public const int EventReminder = 3;
        public const int BookUnavailable = 4;
        public const int EventCancelled = 5;
        public const int NewOrder = 6;
        public const int NewReservation = 7;
        public const int OrderCancelledByUser = 8;
        public const int ReservationCancelledByUser = 9;
    }
}
