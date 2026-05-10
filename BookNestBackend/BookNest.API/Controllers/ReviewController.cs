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
    public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService reviewService) : base(reviewService)
        {
            _reviewService = reviewService;
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<PagedResult<ReviewResponse>> Get([FromQuery] ReviewSearchObject search)
        {
            return await base.Get(search);
        }

        [HttpGet("book/{bookId}")]
        public async Task<ActionResult<List<ReviewResponse>>> GetBookReviews(int bookId)
        {
            var reviews = await _reviewService.GetBookReviewsAsync(bookId);
            return Ok(reviews);
        }

        [HttpGet("book/{bookId}/average-rating")]
        public async Task<ActionResult<double>> GetBookAverageRating(int bookId)
        {
            var averageRating = await _reviewService.GetBookAverageRatingAsync(bookId);
            return Ok(averageRating);
        }

        [HttpGet("event/{eventId}")]
        public async Task<ActionResult<List<ReviewResponse>>> GetEventReviews(int eventId)
        {
            var reviews = await _reviewService.GetEventReviewsAsync(eventId);
            return Ok(reviews);
        }

        [HttpGet("event/{eventId}/average-rating")]
        public async Task<ActionResult<double>> GetEventAverageRating(int eventId)
        {
            var averageRating = await _reviewService.GetEventAverageRatingAsync(eventId);
            return Ok(averageRating);
        }

        [HttpGet("my-reviews")]
        public async Task<ActionResult<List<ReviewResponse>>> GetMyReviews()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0) return Unauthorized();

            var reviews = await _reviewService.GetUserReviewsAsync(userId);
            return Ok(reviews);
        }

        [HttpPost]
        public override async Task<ReviewResponse> Create([FromBody] ReviewInsertRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0) 
                throw new UnauthorizedAccessException();

            return await _reviewService.CreateReviewAsync(userId, request);
        }

        [HttpPut("{id}")]
        public override async Task<ReviewResponse?> Update(int id, [FromBody] ReviewUpdateRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0) return null;

            return await _reviewService.UpdateReviewAsync(id, userId, request);
        }

        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0) return false;

            var isAdmin = User.IsInRole(Roles.Admin);
            return await _reviewService.DeleteReviewAsync(id, userId, isAdmin);
        }
    }
}