using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.BaseControllers
{
    public class BaseController<T, TSearch> : ApiController
        where T : class
        where TSearch : BaseSearchObject
    {
        protected readonly IBaseService<T, TSearch> _service;

        public BaseController(IBaseService<T, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual async Task<PagedResult<T>> Get([FromQuery] TSearch search)
        {
            return await _service.GetAsync(search);
        }

        [HttpGet("{id}")]
        public virtual async Task<T?> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}
