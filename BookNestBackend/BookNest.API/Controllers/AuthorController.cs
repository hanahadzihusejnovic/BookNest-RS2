using BookNest.API.BaseControllers;
using BookNest.API.Helpers;
using BookNest.Model.Constants;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AuthorController : BaseCRUDController<AuthorResponse, AuthorSearchObject, AuthorInsertRequest, AuthorUpdateRequest>
    {
        private readonly IImageService _imageService;

        public AuthorController(IAuthorService service, IImageService imageService) : base(service)
        {
            _imageService = imageService;
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<AuthorResponse> Create([FromBody] AuthorInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<AuthorResponse?> Update(int id, [FromBody] AuthorUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }

        [HttpPost("upload-image")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<ActionResult<object>> UploadImage(IFormFile file)
        {
            await ImageValidationHelper.ValidateImageAsync(file);

            var uniqueName = $"{Guid.NewGuid()}-{file.FileName}";
            using var stream = file.OpenReadStream();
            var url = await _imageService.UploadImageAsync(stream, uniqueName, "author-images");
            return Ok(new { imageUrl = url });
        }
    }
}
