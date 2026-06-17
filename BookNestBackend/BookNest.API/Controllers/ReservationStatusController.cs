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
    public class ReservationStatusController : BaseCRUDController<ReservationStatusResponse, ReservationStatusSearchObject, ReservationStatusInsertRequest, ReservationStatusUpdateRequest>
    {
        public ReservationStatusController(IReservationStatusService service) : base(service)
        {
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<ReservationStatusResponse> Create([FromBody] ReservationStatusInsertRequest request)
        {
            return await base.Create(request);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<ReservationStatusResponse?> Update(int id, [FromBody] ReservationStatusUpdateRequest request)
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
