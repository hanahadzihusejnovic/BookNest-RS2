using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CartController : BaseCRUDController<CartResponse, CartInsertRequest, CartUpdateRequest>
    {
        public CartController(ICartService service) : base(service)
        {
            
        }
    }
}
