using BookNest.Model.Exceptions;
using System.Net;
using System.Text.Json;

namespace BookNest.API.Middleware
{
    public class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;

        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning(ex,
                    "Forbidden access | {Method} {Path} | User: {UserId} | {Message}",
                    context.Request.Method,
                    context.Request.Path,
                    context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous",
                    ex.Message);
                await WriteErrorResponse(context, HttpStatusCode.Forbidden, ex.Message);
            }
            catch (NotFoundException ex)
            {
                _logger.LogWarning(ex,
                    "Resource not found | {Method} {Path} | User: {UserId} | {Message}",
                    context.Request.Method,
                    context.Request.Path,
                    context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous",
                    ex.Message);
                await WriteErrorResponse(context, HttpStatusCode.NotFound, ex.Message);
            }
            catch (BusinessException ex)
            {
                _logger.LogWarning(ex,
                    "Business rule violation | {Method} {Path} | User: {UserId} | {Message}",
                    context.Request.Method,
                    context.Request.Path,
                    context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous",
                    ex.Message);
                await WriteErrorResponse(context, HttpStatusCode.BadRequest, ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Unexpected error | {Method} {Path} | User: {UserId} | Query: {Query}",
                    context.Request.Method,
                    context.Request.Path,
                    context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous",
                    context.Request.QueryString.Value);
                await WriteErrorResponse(context, HttpStatusCode.InternalServerError,
                    "An unexpected error occurred. Please try again later.");
            }
        }

        private static async Task WriteErrorResponse(HttpContext context, HttpStatusCode statusCode, string message)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            var response = new
            {
                status = (int)statusCode,
                message = message
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
    }
}