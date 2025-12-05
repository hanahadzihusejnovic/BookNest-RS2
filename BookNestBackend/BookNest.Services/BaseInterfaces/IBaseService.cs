using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
