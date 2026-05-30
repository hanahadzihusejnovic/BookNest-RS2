using BookNest.API.BaseControllers;
using BookNest.Model.Constants;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class EventReservationController : BaseCRUDController<EventReservationResponse, EventReservationSearchObject, EventReservationInsertRequest, EventReservationUpdateRequest>
    {
        private readonly IEventReservationService _eventReservationService;

        public EventReservationController(IEventReservationService eventReservationService) : base(eventReservationService)
        {
            _eventReservationService = eventReservationService;
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<PagedResult<EventReservationResponse>> Get([FromQuery] EventReservationSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<EventReservationResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [ApiExplorerSettings(IgnoreApi = true)]  
        public override Task<EventReservationResponse> Create([FromBody] EventReservationInsertRequest request)
        {
            throw new NotSupportedException("Use POST /api/EventReservation/reserve instead.");
        }

        [HttpPost("reserve")]
        public async Task<ActionResult<EventReservationResponse>> ReserveEvent([FromBody] EventReservationInsertRequest request)
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var reservation = await _eventReservationService.CreateReservationAsync(userId, request);
            return Ok(reservation);
        }

        [HttpGet("my-reservations")]
        public async Task<ActionResult<List<EventReservationResponse>>> GetMyReservations()
        {
            var userId = GetCurrentUserId();

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var reservations = await _eventReservationService.GetUserReservationsAsync(userId);
            return Ok(reservations);
        }

        [HttpGet("event/{eventId}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<List<EventReservationResponse>>> GetEventReservations(int eventId)
        {
            var reservations = await _eventReservationService.GetEventReservationsAsync(eventId);
            return Ok(reservations);
        }

        [HttpGet("available-seats/{eventId}")]
        public async Task<ActionResult<int>> GetAvailableSeats(int eventId)
        {
            var availableSeats = await _eventReservationService.GetAvailableSeatsAsync(eventId);
            return Ok(availableSeats);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<EventReservationResponse?> Update(int id, [FromBody] EventReservationUpdateRequest request)
        {
            var adminId = GetCurrentUserId();
            return await _eventReservationService.UpdateStatusAsync(id, request, adminId);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpPost("{id}/cancel")]
        public async Task<ActionResult<EventReservationResponse>> CancelReservation(int id, [FromBody] string cancellationReason)
        {
            var userId = GetCurrentUserId();
            if (userId == 0) return Unauthorized();

            var result = await _eventReservationService.CancelUserReservationAsync(id, userId, cancellationReason);
            return Ok(result);
        }

        [Authorize(Roles = Roles.Admin)]
        [HttpPost("{id}/send-reminder")]
        public async Task<ActionResult> SendReminder(int id)
        {
            await _eventReservationService.SendReminderAsync(id);
            return Ok(new { message = "Reminder sent successfully." });
        }
    }
}

