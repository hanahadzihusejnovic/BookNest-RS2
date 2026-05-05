using BookNest.Model.Responses;
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly BookNestDbContext _dbContext;

        public DashboardService(BookNestDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<List<CategoryStatResponse>> GetCategoryOrderStatsAsync(CancellationToken cancellationToken = default)
        {
            var stats = await _dbContext.Categories
                .Select(c => new CategoryStatResponse
                {
                    CategoryName = c.Name,
                    OrderCount = _dbContext.OrderItems
                        .Count(oi => oi.Book.BookCategories
                            .Any(bc => bc.CategoryId == c.Id))
                })
                .Where(c => c.OrderCount > 0)
                .OrderByDescending(c => c.OrderCount)
                .Take(6)
                .ToListAsync(cancellationToken);

            return stats;
        }
    }
}