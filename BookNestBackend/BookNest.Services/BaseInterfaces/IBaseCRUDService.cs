using BookNest.Model.SearchObjects;

namespace BookNest.Services.BaseInterfaces
{
    public interface IBaseCRUDService<T, TSearch, TInsert, TUpdate> : IBaseService<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TInsert : class
        where TUpdate : class
    {
        Task<T> CreateAsync(TInsert request, CancellationToken cancellationToken = default);
        Task<T?> UpdateAsync(int id, TUpdate request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
