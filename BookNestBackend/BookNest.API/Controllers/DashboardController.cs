using BookNest.Model.Responses;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _dashboardService;

        public DashboardController(IDashboardService dashboardService)
        {
            _dashboardService = dashboardService;
        }

        [HttpGet("category-stats")]
        public async Task<ActionResult<List<CategoryStatResponse>>> GetCategoryStats()
        {
            var stats = await _dashboardService.GetCategoryOrderStatsAsync();
            return Ok(stats);
        }
    }
}