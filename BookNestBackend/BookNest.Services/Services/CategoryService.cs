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
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryInserRequest, CategoryUpdateRequest>, ICategoryService
    {
        public CategoryService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Text))
            {
                var lower = search.Text.ToLower();

                query = query.Where(
                    c => c.Name != null && c.Name.ToLower().Contains(lower)
                );
            }

            if (!string.IsNullOrWhiteSpace(search.Name))
            {
                query = query.Where(c => c.Name != null && c.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }
    }
}
