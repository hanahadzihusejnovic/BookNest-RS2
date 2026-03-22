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
    public interface IBookService : IBaseCRUDService<BookResponse, BookSearchObject, BookInsertRequest, BookUpdateRequest>
    {
        Task<List<BookResponse>> GetRecommendedBooksAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
        Task<List<BookResponse>> GetContentBasedRecommendationsAsync(int userId, int count = 6, CancellationToken cancellationToken = default);
    }
}
