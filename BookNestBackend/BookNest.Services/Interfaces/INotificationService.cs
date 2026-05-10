using BookNest.Model.Messages;
using BookNest.Model.Responses;

namespace BookNest.Services.Interfaces
{
    public interface INotificationService
    {
        Task SaveAsync(NotificationMessage message);
        Task<List<NotificationResponse>> GetForUserAsync(int userId);
        Task MarkAsReadAsync(int notificationId, int userId);
        Task MarkAllAsReadAsync(int userId);
    }
}