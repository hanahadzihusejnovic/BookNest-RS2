using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using BookNest.Services.MessageQueue;
using BookNest.Model.Messages;
using System.Security.Cryptography;

namespace BookNest.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly IRabbitMqPublisher _rabbitMqPublisher;

        public AuthController(IAuthService authService, IRabbitMqPublisher rabbitMqPublisher)
        {
            _authService = authService;
            _rabbitMqPublisher = rabbitMqPublisher;
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        {
            var response = await _authService.LoginAsync(request);

            if (response == null)
            {
                return Unauthorized(new { message = "Invalid username or password." });
            }

            return Ok(response);
        }

        [HttpPost("register")]
        public async Task<ActionResult<UserResponse>> Register([FromBody] UserInsertRequest request)
        {
            try
            {
                var response = await _authService.RegisterAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            try
            {
                var user = await _authService.GetByEmailAsync(request.Email);

                if (user == null)
                {
                    return Ok(new { message = "If the email exists, a password reset link will be sent." });
                }

                var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
                var expiresAt = DateTime.UtcNow.AddHours(1);

                await _authService.CreatePasswordResetTokenAsync(user.Id, token, expiresAt);

                var message = new PasswordResetEmailMessage
                {
                    Email = user.EmailAddress,
                    Token = token,
                    UserName = $"{user.FirstName} {user.LastName}",
                    ExpiresAt = expiresAt
                };

                await _rabbitMqPublisher.PublishAsync("password-reset-queue", message);

                return Ok(new { message = "If the email exists, a password reset link will be sent." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while processing your request." });
            }
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            try
            {
                await _authService.ResetPasswordAsync(request);
                return Ok(new { message = "Password reset successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
