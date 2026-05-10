using BookNest.Model.Enums;
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
            var notification = new Notification
            {
                UserId = message.UserId,
                BookId = message.BookId,
                EventId = message.EventId,
                Title = message.Title,
                Message = message.Message,
                NotificationType = Enum.Parse<NotificationType>(message.NotificationType),
                IsRead = false,
                SendAt = message.SendAt
            };

            _dbContext.Notifications.Add(notification);
            await _dbContext.SaveChangesAsync();
        }

        public async Task<List<NotificationResponse>> GetForUserAsync(int userId)
        {
            var notifications = await _dbContext.Notifications
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
                NotificationType = n.NotificationType.ToString(),
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
            var notifications = await _dbContext.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var n in notifications)
                n.IsRead = true;

            await _dbContext.SaveChangesAsync();
        }
    }
}