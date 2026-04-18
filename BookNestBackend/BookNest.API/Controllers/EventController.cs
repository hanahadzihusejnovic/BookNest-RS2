using BookNest.API.BaseControllers;
using BookNest.Infrastructure.Services;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class EventController : BaseCRUDController<EventResponse, EventSearchObject, EventInsertRequest, EventUpdateRequest>
    {
        private readonly IEventService _eventService;
        private readonly IImageService _imageService;

        public EventController(IEventService eventService, IImageService imageService) : base(eventService)
        {
            _eventService = eventService;
            _imageService = imageService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<EventResponse> Create([FromBody] EventInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<EventResponse?> Update(int id, [FromBody] EventUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpGet("recommended")]
        public async Task<ActionResult<List<EventResponse>>> GetRecommended([FromQuery] int count = 6)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var events = await _eventService.GetRecommendedEventsAsync(userId, count);
            return Ok(events);
        }

        [HttpGet("recommended-content")]
        public async Task<ActionResult<List<EventResponse>>> GetContentRecommended([FromQuery] int count = 6)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var events = await _eventService.GetContentBasedRecommendationsAsync(userId, count);
            return Ok(events);
        }

        [HttpPost("upload-image")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<object>> UploadImage(IFormFile file, [FromQuery] string? category = null)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded");

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
                return BadRequest("Only image files are allowed");

            var folder = category?.ToLower() ?? "misc";
            var uniqueName = $"{folder}/{Guid.NewGuid()}-{file.FileName}";
            using var stream = file.OpenReadStream();
            var url = await _imageService.UploadImageAsync(stream, uniqueName, "event-images");
            return Ok(new { url });
        }
    }
}
