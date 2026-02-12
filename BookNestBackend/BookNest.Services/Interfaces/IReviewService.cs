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
    public interface IReviewService : IBaseCRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        Task<List<ReviewResponse>> GetBookReviewsAsync(int bookId, CancellationToken cancellationToken = default);
        Task<List<ReviewResponse>> GetEventReviewsAsync(int eventId, CancellationToken cancellationToken = default);
        Task<List<ReviewResponse>> GetUserReviewsAsync(int userId, CancellationToken cancellationToken = default);
        Task<double> GetBookAverageRatingAsync(int bookId, CancellationToken cancellationToken = default);
        Task<double> GetEventAverageRatingAsync(int eventId, CancellationToken cancellationToken = default);
    }
}
