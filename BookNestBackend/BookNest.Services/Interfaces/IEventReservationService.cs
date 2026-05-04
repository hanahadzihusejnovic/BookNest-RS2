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
    public interface IEventReservationService : IBaseCRUDService<EventReservationResponse, EventReservationSearchObject, EventReservationInsertRequest, EventReservationUpdateRequest>
    {
        Task<EventReservationResponse> CreateReservationAsync(int userId, EventReservationInsertRequest request, CancellationToken cancellationToken = default);
        Task<List<EventReservationResponse>> GetUserReservationsAsync(int userId, CancellationToken cancellationToken = default);
        Task<List<EventReservationResponse>> GetEventReservationsAsync(int eventId, CancellationToken cancellationToken = default);
        Task<int> GetAvailableSeatsAsync(int eventId, CancellationToken cancellationToken = default);
        Task SendReminderAsync(int reservationId, CancellationToken cancellationToken = default);
    }
}
