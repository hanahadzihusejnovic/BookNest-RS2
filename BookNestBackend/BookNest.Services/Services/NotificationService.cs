using BookNest.Model.Exceptions;
using BookNest.Model.Messages;
using BookNest.Model.Responses;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly BookNestDbContext _dbContext;

        public NotificationService(BookNestDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task SaveAsync(NotificationMessage message)
        {
            var notificationType = await _dbContext.NotificationTypes
                .FirstOrDefaultAsync(nt => nt.Name == message.NotificationType);
            if (notificationType == null)
                throw new ArgumentException($"Invalid notification type: '{message.NotificationType}'.");

            var notification = new Notification
            {
                UserId = message.UserId,
                BookId = message.BookId,
                EventId = message.EventId,
                Title = message.Title,
                Message = message.Message,
                NotificationTypeId = notificationType.Id,
                IsRead = false,
                SendAt = message.SendAt
            };

            _dbContext.Notifications.Add(notification);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<List<NotificationResponse>> GetForUserAsync(int userId)
        {
            var notifications = await _dbContext.Notifications
                .Include(n => n.NotificationType)
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.SendAt)
                .ToListAsync();

            return notifications.Select(n => new NotificationResponse
            {
                Id = n.Id,
                UserId = n.UserId,
                BookId = n.BookId,
                EventId = n.EventId,
                Title = n.Title,
                Message = n.Message,
                NotificationTypeId = n.NotificationTypeId,
                NotificationTypeName = n.NotificationType?.Name ?? string.Empty,
                IsRead = n.IsRead,
                SendAt = n.SendAt
            }).ToList();
        }

        public async Task MarkAsReadAsync(int notificationId, int userId)
        {
            var notification = await _dbContext.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null)
                throw new NotFoundException("Notification not found.");

            notification.IsRead = true;
            await _dbContext.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(int userId)
        {
            await _dbContext.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        }
    }
}
