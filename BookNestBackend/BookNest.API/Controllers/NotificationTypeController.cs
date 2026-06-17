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
    public class NotificationTypeController : BaseCRUDController<NotificationTypeResponse, NotificationTypeSearchObject, NotificationTypeInsertRequest, NotificationTypeUpdateRequest>
    {
        public NotificationTypeController(INotificationTypeService service) : base(service)
        {
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<NotificationTypeResponse> Create([FromBody] NotificationTypeInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<NotificationTypeResponse?> Update(int id, [FromBody] NotificationTypeUpdateRequest request)
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
