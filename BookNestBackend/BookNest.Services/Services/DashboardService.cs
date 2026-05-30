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
            return await _dbContext.OrderItems
                .SelectMany(oi => oi.Book.BookCategories)
                .GroupBy(bc => bc.Category.Name)
                .Select(g => new CategoryStatResponse
                {
                    CategoryName = g.Key,
                    OrderCount = g.Count()
                })
                .Where(c => c.OrderCount > 0)
                .OrderByDescending(c => c.OrderCount)
                .Take(6)
                .ToListAsync(cancellationToken);
        }
    }
}