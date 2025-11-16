using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.BaseInterfaces
{
    public interface IBaseCRUDService<T, TInsert, TUpdate> : IBaseService<T>
        where T : class
        where TInsert : class
        where TUpdate : class
    {
        Task<T> CreateAsync(TInsert request, CancellationToken cancellationToken = default);
        Task<T?> UpdateAsync(int id, TUpdate request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
