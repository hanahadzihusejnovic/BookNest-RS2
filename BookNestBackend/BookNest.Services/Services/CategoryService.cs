using AutoMapper;
using BookNest.Model.Exceptions;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Model.SearchObjects;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class CategoryService : BaseCRUDService<CategoryResponse, CategorySearchObject, Category, CategoryInserRequest, CategoryUpdateRequest>, ICategoryService
    {
        private readonly BookNestDbContext _dbContext;

        public CategoryService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
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
                query = query.Where(c =>
                    c.Name != null &&
                    c.Name.ToLower().Contains(search.Name.ToLower()));
            }

            return query;
        }

        public override async Task<CategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var category = await _dbContext.Categories
                .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

            if (category == null)
            {
                throw new NotFoundException("Category not found.");
            }

            return _mapper.Map<CategoryResponse>(category);
        }

        public override async Task<CategoryResponse?> UpdateAsync(int id, CategoryUpdateRequest request, CancellationToken cancellationToken = default)
        {
            var category = await _dbContext.Categories
                .FindAsync(new object[] { id }, cancellationToken);

            if (category == null)
            {
                throw new NotFoundException("Category not found.");
            }

            _mapper.Map(request, category);

            await _dbContext.SaveChangesAsync(cancellationToken);

            return await GetByIdAsync(id, cancellationToken);
        }
    }
}