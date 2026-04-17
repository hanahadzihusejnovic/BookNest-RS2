using BookNest.API.BaseControllers;
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
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly IImageService _imageService;

        public UserController(IUserService service, IImageService imageService) : base(service)
        {
            _userService = service;
            _imageService = imageService;
        }

        [Authorize(Roles = "Admin")]
        public override async Task<PagedResult<UserResponse>> Get([FromQuery] UserSearchObject search)
        {
            return await base.Get(search);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<UserResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<UserResponse> Create([FromBody] UserInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<UserResponse?> Update(int id, [FromBody] UserUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpGet("current-user")]
        public async Task<ActionResult<UserResponse>> GetCurrentUser()
        {
            var userId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var user = await _userService.GetByIdAsync(userId);
            if (user == null)
                return NotFound();

            return Ok(user);
        }

        [HttpPut("update-self")]
        public async Task<ActionResult<UserResponse>> UpdateSelf([FromBody] UserSelfUpdateRequest request)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0)
                return Unauthorized();

            var result = await _userService.UpdateSelfAsync(userId, request);
            if (result == null)
                return NotFound();

            return Ok(result);
        }

        [HttpDelete("delete-self")]
        public async Task<ActionResult> DeleteSelf()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            if (userId == 0) return Unauthorized();

            await _userService.DeactivateSelfAsync(userId);
            return Ok();
        }

        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadImage(IFormFile image)
        {
            if (image == null || image.Length == 0)
                return BadRequest("No image provided.");

            var uniqueName = $"{Guid.NewGuid()}-{image.FileName}";
            using var stream = image.OpenReadStream();
            var imageUrl = await _imageService.UploadImageAsync(stream, uniqueName, "user-images");
            return Ok(new { imageUrl });
        }


    }
}