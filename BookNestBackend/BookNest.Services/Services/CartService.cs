using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Services
{
    public class CartService : BaseCRUDService<CartResponse, BaseSearchObject, Cart, CartInsertRequest, CartUpdateRequest>, ICartService
    {
        public CartService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            
        }
    }
}
