using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Database.Entities;
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

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<EventReservationResponse>> Get([FromQuery] EventReservationSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = "Admin")]
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
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var reservation = await _eventReservationService.CreateReservationAsync(userId, request);
                return Ok(reservation);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("my-reservations")]
        public async Task<ActionResult<List<EventReservationResponse>>> GetMyReservations()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var reservations = await _eventReservationService.GetUserReservationsAsync(userId);
            return Ok(reservations);
        }

        [Authorize(Roles = "Admin")]
        [HttpGet("event/{eventId}")]
        public async Task<ActionResult<List<EventReservationResponse>>> GetEventReservations(int eventId)
        {
            var reservations = await _eventReservationService.GetEventReservationsAsync(eventId);
            return Ok(reservations);
        }

        [AllowAnonymous]
        [HttpGet("available-seats/{eventId}")]
        public async Task<ActionResult<int>> GetAvailableSeats(int eventId)
        {
            try
            {
                var availableSeats = await _eventReservationService.GetAvailableSeatsAsync(eventId);
                return Ok(availableSeats);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [Authorize(Roles = "Admin")]
        public override async Task<EventReservationResponse?> Update(int id, [FromBody] EventReservationUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}
