using BookNest.API.Hubs;
using BookNest.Model.Messages;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationController : ControllerBase
    {
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationController(IHubContext<NotificationHub> hubContext)
        {
            _hubContext = hubContext;
        }

        [HttpPost("send")]
        public async Task<IActionResult> Send([FromBody] NotificationMessage message)
        {
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
    }
}