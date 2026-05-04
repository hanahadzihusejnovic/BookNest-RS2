using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Model.Enums
{
    public enum NotificationType
    {
        OrderStatusChanged,
        ReservationStatusChanged,
        EventReminder,
        BookUnavailable,
        EventCancelled
    }
}
