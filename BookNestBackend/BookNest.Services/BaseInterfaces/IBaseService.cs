using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;

namespace BookNest.Services.BaseInterfaces
{
    public interface IBaseService<T, TSearch> 
        where T: class
        where TSearch : BaseSearchObject
    {
        Task<PagedResult<T>> GetAsync(TSearch search, CancellationToken cancellationToken = default);
        Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    }
}
