using BookNest.API.BaseControllers;
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
    public class ReadingStatusController : BaseCRUDController<ReadingStatusResponse, ReadingStatusSearchObject, ReadingStatusInsertRequest, ReadingStatusUpdateRequest>
    {
        public ReadingStatusController(IReadingStatusService service) : base(service)
        {
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<ReadingStatusResponse> Create([FromBody] ReadingStatusInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<ReadingStatusResponse?> Update(int id, [FromBody] ReadingStatusUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<bool> Delete(int id)
        {
            return await base.Delete(id);
        }
    }
}
