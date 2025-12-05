using BookNest.API.BaseControllers;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BookController : BaseCRUDController<BookResponse, BookSearchObject, BookInsertRequest, BookUpdateRequest>
    {
        public BookController(IBookService service) : base(service)
        {
            
        }
    }
}
