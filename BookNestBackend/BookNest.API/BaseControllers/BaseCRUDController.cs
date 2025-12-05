using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.BaseControllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TInsert : class
        where TUpdate : class
    {
        protected readonly IBaseCRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(IBaseCRUDService<T, TSearch, TInsert, TUpdate> crudService) : base(crudService)
        {
            _crudService = crudService;
        }

        [HttpPost]
        public virtual async Task<T> Create([FromBody] TInsert request)
        {
            return await _crudService.CreateAsync(request);
        }

        [HttpPut("{id}")]
        public virtual async Task<T?> Update(int id, [FromBody] TUpdate request)
        {
            return await _crudService.UpdateAsync(id, request);
        }

        [HttpDelete("{id}")]
        public virtual async Task<bool> Delete(int id)
        {
            return await _crudService.DeleteAsync(id);
        }
    }
}
