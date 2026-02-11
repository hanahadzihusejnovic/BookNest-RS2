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
    public class FavoriteController : BaseController<FavoriteResponse, BaseSearchObject>
    {
        private readonly IFavoriteService _favoriteService;

        public FavoriteController(IFavoriteService favoriteService) : base(favoriteService)
        {
            _favoriteService = favoriteService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<FavoriteResponse>> Get([FromQuery] BaseSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<FavoriteResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpGet("my-favorites")]
        public async Task<ActionResult<List<FavoriteResponse>>> GetMyFavorites()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var favorites = await _favoriteService.GetUserFavoritesAsync(userId);
            return Ok(favorites);
        }

        [HttpPost("add")]
        public async Task<ActionResult<FavoriteResponse>> AddToFavorites([FromBody] FavoriteInsertRequest request)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (userId == 0)
                {
                    return Unauthorized(new { message = "User not authenticated." });
                }

                var favorite = await _favoriteService.AddToFavoritesAsync(userId, request);
                return Ok(favorite);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("remove/{bookId}")]
        public async Task<ActionResult<bool>> RemoveFromFavorites(int bookId)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _favoriteService.RemoveFromFavoritesAsync(userId, bookId);

            if (!result)
            {
                return NotFound(new { message = "Book not found in favorites." });
            }

            return Ok(result);
        }

        [HttpGet("check/{bookId}")]
        public async Task<ActionResult<bool>> IsBookInFavorites(int bookId)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var result = await _favoriteService.IsBookInFavoritesAsync(userId, bookId);
            return Ok(result);
        }
    }
}
