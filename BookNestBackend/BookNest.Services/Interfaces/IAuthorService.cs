using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseInterfaces;

namespace BookNest.Services.Interfaces
{
    public interface IAuthorService : IBaseCRUDService<AuthorResponse, AuthorSearchObject, AuthorInsertRequest, AuthorUpdateRequest>
    {
    }
}
