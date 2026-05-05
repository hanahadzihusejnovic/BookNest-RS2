using BookNest.Model.Responses;

namespace BookNest.Services.Interfaces
{
    public interface IDashboardService
    {
        Task<List<CategoryStatResponse>> GetCategoryOrderStatsAsync(CancellationToken cancellationToken = default);
    }
}