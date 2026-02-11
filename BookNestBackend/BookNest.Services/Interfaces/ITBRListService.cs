using BookNest.Model.Enums;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Interfaces
{
    public interface ITBRListService : IBaseService<TBRListResponse, BaseSearchObject>
    {
        Task<List<TBRListResponse>> GetUserTBRListAsync(int userId, ReadingStatus? status = null, CancellationToken cancellationToken = default);
        Task<TBRListResponse> AddToTBRListAsync(int userId, TBRListInsertRequest request, CancellationToken cancellationToken = default);
        Task<TBRListResponse> UpdateTBRListStatusAsync(int userId, int bookId, ReadingStatus status, CancellationToken cancellationToken = default);
        Task<bool> RemoveFromTBRListAsync(int userId, int bookId, CancellationToken cancellationToken = default);
        Task<bool> IsBookInTBRListAsync(int userId, int bookId, CancellationToken cancellationToken = default);
    }
}
