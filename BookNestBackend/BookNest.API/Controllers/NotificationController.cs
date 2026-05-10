using BookNest.API.Hubs;
using BookNest.Model.Messages;
using BookNest.Model.Responses;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationController : ControllerBase
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
        [Authorize]
        public async Task<ActionResult<List<NotificationResponse>>> GetMyNotifications()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var notifications = await _notificationService.GetForUserAsync(userId);
            return Ok(notifications);
        }

        [HttpPut("{id}/mark-read")]
        [Authorize]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            await _notificationService.MarkAsReadAsync(id, userId);
            return Ok();
        }

        [HttpPut("mark-all-read")]
        [Authorize]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            await _notificationService.MarkAllAsReadAsync(userId);
            return Ok();
        }
    }
}