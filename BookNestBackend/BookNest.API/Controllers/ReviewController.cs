using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;
        private readonly BookNestDbContext _dbContext;

        public ReviewController(IReviewService reviewService, BookNestDbContext dbContext) : base(reviewService)
        {
            _reviewService = reviewService;
            _dbContext = dbContext;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<ReviewResponse>> Get([FromQuery] ReviewSearchObject search)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<ReviewResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [AllowAnonymous]
        [HttpGet("book/{bookId}")]
        public async Task<ActionResult<List<ReviewResponse>>> GetBookReviews(int bookId)
        {
            var reviews = await _reviewService.GetBookReviewsAsync(bookId);
            return Ok(reviews);
        }

        [AllowAnonymous]
        [HttpGet("book/{bookId}/average-rating")]
        public async Task<ActionResult<double>> GetBookAverageRating(int bookId)
        {
            var averageRating = await _reviewService.GetBookAverageRatingAsync(bookId);
            return Ok(averageRating);
        }

        [AllowAnonymous]
        [HttpGet("event/{eventId}")]
        public async Task<ActionResult<List<ReviewResponse>>> GetEventReviews(int eventId)
        {
            var reviews = await _reviewService.GetEventReviewsAsync(eventId);
            return Ok(reviews);
        }

        [AllowAnonymous]
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

            if (userId == 0)
            {
                return Unauthorized(new { message = "User not authenticated." });
            }

            var reviews = await _reviewService.GetUserReviewsAsync(userId);
            return Ok(reviews);
        }

        public override async Task<ReviewResponse> Create([FromBody] ReviewInsertRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return new ReviewResponse();
            }

            var review = new Review
            {
                UserId = userId,
                BookId = request.BookId,
                EventId = request.EventId,
                Rating = request.Rating,
                Comment = request.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Reviews.Add(review);
            await _dbContext.SaveChangesAsync();

            return await _reviewService.GetByIdAsync(review.Id) ?? new ReviewResponse();
        }

        [HttpPut("{id}")]
        public override async Task<ReviewResponse?> Update(int id, [FromBody] ReviewUpdateRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

            if (userId == 0)
            {
                return null;
            }

            var review = await _dbContext.Reviews.FindAsync(id);
            if (review == null || review.UserId != userId)
            {
                return null;
            }

            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override async Task<bool> Delete(int id)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

            if (userId == 0)
            {
                return false;
            }

            if (userRole == "Admin")
            {
                return await base.Delete(id);
            }

            var review = await _dbContext.Reviews.FindAsync(id);
            if (review == null || review.UserId != userId)
            {
                return false;
            }

            return await base.Delete(id);
        }
    }
}
