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
    public class OrganizerController : BaseCRUDController<OrganizerResponse,OrganizerSearchObject, OrganizerInsertRequest, OrganizerUpdateRequest>
    {
        public OrganizerController(IOrganizerService service) : base(service)
        {
            
        }

        [Authorize(Roles = "Admin")]
        public override async Task<OrganizerResponse> Create([FromBody] OrganizerInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = "Admin")]
        public override async Task<OrganizerResponse?> Update(int id, [FromBody] OrganizerUpdateRequest request)
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
