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
    public class CartController : BaseCRUDController<CartResponse, BaseSearchObject, CartInsertRequest, CartUpdateRequest>
    {
        public CartController(ICartService service) : base(service)
        {
            
        }
    }
}
