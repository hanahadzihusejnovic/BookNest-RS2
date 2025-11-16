using BookNest.Services.BaseInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.BaseControllers
{
    public class BaseCRUDController<T, TInsert, TUpdate> : BaseController<T>
        where T : class
        where TInsert : class
        where TUpdate : class
    {
        protected readonly IBaseCRUDService<T, TInsert, TUpdate> _crudService;

        public BaseCRUDController(IBaseCRUDService<T, TInsert, TUpdate> crudService) : base(crudService)
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
