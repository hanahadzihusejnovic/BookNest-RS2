using BookNest.API.BaseControllers;
using BookNest.API.Hubs;
using BookNest.Model.Constants;
using BookNest.Model.Messages;
using BookNest.Model.Responses;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace BookNest.API.Controllers
{
    [Authorize]
    public class NotificationController : ApiController
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly INotificationService _notificationService;

        public NotificationController(
            IHubContext<NotificationHub> hubContext,
            INotificationService notificationService)
        {
            _hubContext = hubContext;
            _notificationService = notificationService;
        }

        [HttpPost("send")]
        [Authorize(AuthenticationSchemes = "ApiKey")]
        public async Task<IActionResult> Send([FromBody] NotificationMessage message)
        {
            await _notificationService.SaveAsync(message);

            await _hubContext.Clients
                .Group($"user-{message.UserId}")
                .SendAsync("ReceiveNotification", new
                {
                    message.Title,
                    message.Message,
                    message.NotificationType,
                    message.SendAt
                });

            return Ok();
        }

        [HttpGet("my-notifications")]
        public async Task<ActionResult<List<NotificationResponse>>> GetMyNotifications()
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                return Unauthorized();

            var notifications = await _notificationService.GetForUserAsync(userId);
            return Ok(notifications);
        }

        [HttpPut("{id}/mark-read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                return Unauthorized();

            await _notificationService.MarkAsReadAsync(id, userId);
            return Ok();
        }

        [HttpPut("mark-all-read")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                return Unauthorized();

            await _notificationService.MarkAllAsReadAsync(userId);
            return Ok();
        }
    }
}