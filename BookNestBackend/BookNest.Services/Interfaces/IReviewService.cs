using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;

namespace BookNest.Services.Interfaces
{
    public interface IReviewService : IBaseCRUDService<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        Task<List<ReviewResponse>> GetBookReviewsAsync(int bookId, CancellationToken cancellationToken = default);
        Task<List<ReviewResponse>> GetEventReviewsAsync(int eventId, CancellationToken cancellationToken = default);
        Task<List<ReviewResponse>> GetUserReviewsAsync(int userId, CancellationToken cancellationToken = default);
        Task<double> GetBookAverageRatingAsync(int bookId, CancellationToken cancellationToken = default);
        Task<double> GetEventAverageRatingAsync(int eventId, CancellationToken cancellationToken = default);
        Task<ReviewResponse> CreateReviewAsync(int userId, ReviewInsertRequest request, CancellationToken cancellationToken = default);
        Task<ReviewResponse?> UpdateReviewAsync(int id, int userId, ReviewUpdateRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteReviewAsync(int id, int userId, bool isAdmin, CancellationToken cancellationToken = default);
    }
}
