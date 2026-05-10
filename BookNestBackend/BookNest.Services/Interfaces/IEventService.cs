using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;

namespace BookNest.Services.Interfaces
{
    public interface IEventService : IBaseCRUDService<EventResponse, EventSearchObject, EventInsertRequest, EventUpdateRequest>
    {
        Task<List<EventRecommendationResponse>> GetRecommendedEventsAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
        Task<List<EventRecommendationResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
    }
}