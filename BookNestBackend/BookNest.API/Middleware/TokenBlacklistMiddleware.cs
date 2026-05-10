using BookNest.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace BookNest.API.Middleware
{
    public class TokenBlacklistMiddleware
    {
        private readonly RequestDelegate _next;

        public TokenBlacklistMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, BookNestDbContext dbContext)
        {
            var token = context.Request.Headers["Authorization"].ToString().Replace("Bearer ", "");

            if (!string.IsNullOrEmpty(token))
            {
                var isRevoked = await dbContext.RevokedTokens
                    .AnyAsync(t => t.Token == token && t.ExpiresAt > DateTime.UtcNow);

                if (isRevoked)
                {
                    context.Response.StatusCode = 401;
                    await context.Response.WriteAsJsonAsync(new { message = "Token has been revoked." });
                    return;
                }
            }

            await _next(context);
        }
    }
}