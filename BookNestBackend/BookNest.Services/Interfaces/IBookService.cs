using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;

namespace BookNest.Services.Interfaces
{
    public interface IBookService : IBaseCRUDService<BookResponse, BookSearchObject, BookInsertRequest, BookUpdateRequest>
    {
        Task<List<BookRecommendationResponse>> GetRecommendedBooksAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
        Task<List<BookRecommendationResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
    }
}