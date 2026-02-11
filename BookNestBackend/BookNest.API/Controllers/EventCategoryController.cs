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
    public class EventCategoryController : BaseCRUDController<EventCategoryResponse, EventCategorySearchObject, EventCategoryInsertRequest, EventCategoryUpdateRequest>
    {
        public EventCategoryController(IEventCategoryService service) : base(service)
        {
            
        }

        [Authorize(Roles = "Admin")]
        public override async Task<EventCategoryResponse> Create([FromBody] EventCategoryInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<EventCategoryResponse?> Update(int id, [FromBody] EventCategoryUpdateRequest request)
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
