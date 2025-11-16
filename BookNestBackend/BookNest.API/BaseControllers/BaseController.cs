using BookNest.Services.BaseInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.BaseControllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseController<T> : ControllerBase 
        where T : class
    {
        protected readonly IBaseService<T> _service;

        public BaseController(IBaseService<T> service)
        {
            _service = service;
        }

        [HttpGet("{id}")]
        public virtual async Task<T?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}
