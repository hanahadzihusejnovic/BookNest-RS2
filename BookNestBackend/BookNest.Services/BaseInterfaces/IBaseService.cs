using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.BaseInterfaces
{
    public interface IBaseService<T> 
        where T: class
    {
        Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    }
}
