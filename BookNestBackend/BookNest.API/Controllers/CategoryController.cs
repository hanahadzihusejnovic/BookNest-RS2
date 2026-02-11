using BookNest.API.BaseControllers;
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
    public class CategoryController : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoryInserRequest, CategoryUpdateRequest>
    {
        public CategoryController(ICategoryService service) : base(service)
        {
            
        }

        [Authorize(Roles = "Admin")]
        public override async Task<CategoryResponse> Create([FromBody] CategoryInserRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<CategoryResponse?> Update(int id, [FromBody] CategoryUpdateRequest request)
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
