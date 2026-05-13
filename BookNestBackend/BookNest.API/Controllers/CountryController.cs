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
    public class CountryController : BaseCRUDController<CountryResponse, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountryController(ICountryService service) : base(service)
        {
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<CountryResponse> Create([FromBody] CountryInsertRequest request)
        {
            return await base.Create(request);
        }

        [AllowAnonymous]
        public override async Task<PagedResult<CountryResponse>> Get([FromQuery] CountrySearchObject search)
        {
            return await base.Get(search);
        }

        [AllowAnonymous]
        public override async Task<CountryResponse?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [Authorize(Roles = Roles.Admin)]
        public override async Task<CountryResponse?> Update(int id, [FromBody] CountryUpdateRequest request)
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