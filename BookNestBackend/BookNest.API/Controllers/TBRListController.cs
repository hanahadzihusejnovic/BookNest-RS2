using BookNest.API.BaseControllers;
using BookNest.Model.Enums;
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
    public class TBRListController : BaseController<TBRListResponse, BaseSearchObject>
    {
        private readonly ITBRListService _tbrListService;

        public TBRListController(ITBRListService tbrListService) : base(tbrListService)
        {
            _tbrListService = tbrListService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<TBRListResponse>> Get([FromQuery] BaseSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<TBRListResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpGet("my-tbr-list")]
        public async Task<ActionResult<List<TBRListResponse>>> GetMyTBRList([FromQuery] ReadingStatus? status = null)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var tbrList = await _tbrListService.GetUserTBRListAsync(userId, status);
            return Ok(tbrList);
        }

        [HttpPost("add")]
        public async Task<ActionResult<TBRListResponse>> AddToTBRList([FromBody] TBRListInsertRequest request)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var tbrItem = await _tbrListService.AddToTBRListAsync(userId, request);
                return Ok(tbrItem);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("update-status/{bookId}")]
        public async Task<ActionResult<TBRListResponse>> UpdateStatus(int bookId, [FromBody] ReadingStatus status)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var tbrItem = await _tbrListService.UpdateTBRListStatusAsync(userId, bookId, status);
                return Ok(tbrItem);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("remove/{bookId}")]
        public async Task<ActionResult<bool>> RemoveFromTBRList(int bookId)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _tbrListService.RemoveFromTBRListAsync(userId, bookId);

            if (!result)
            {
                return NotFound(new { message = "Book not found in TBR list." });
            }

            return Ok(result);
        }

        [HttpGet("check/{bookId}")]
        public async Task<ActionResult<bool>> IsBookInTBRList(int bookId)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _tbrListService.IsBookInTBRListAsync(userId, bookId);
            return Ok(result);
        }
    }
}
