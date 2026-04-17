using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using BookNest.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class BookController : BaseCRUDController<BookResponse, BookSearchObject, BookInsertRequest, BookUpdateRequest>
    {
        private readonly IImageService _imageService;
        private readonly IBookService _bookService;

        public BookController(IBookService bookService, IImageService imageService) : base(bookService)
        {
            _bookService = bookService;
            _imageService = imageService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<BookResponse> Create([FromBody] BookInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<BookResponse?> Update(int id, [FromBody] BookUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpPost("upload-cover")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<object>> UploadCoverImage(IFormFile file, [FromQuery] string? category = null)
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
            var imageUrl = await _imageService.UploadImageAsync(stream, uniqueName, "book-covers");
            return Ok(new { url = imageUrl });
        }


        [HttpGet("recommended")]
        public async Task<ActionResult<List<BookResponse>>> GetRecommended([FromQuery] int count = 6)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var books = await _bookService.GetRecommendedBooksAsync(userId, count);
            return Ok(books);
        }

        [HttpGet("recommended-content")]
        public async Task<ActionResult<List<BookResponse>>> GetContentRecommended([FromQuery] int count = 6)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var books = await _bookService.GetContentBasedRecommendationsAsync(userId, count);
            return Ok(books);
        }
    }
}
