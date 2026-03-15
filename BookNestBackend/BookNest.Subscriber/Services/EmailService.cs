using BookNest.Subscriber.Models;
using MailKit.Net.Smtp;
using MimeKit;

namespace BookNest.Subscriber.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendPasswordResetEmailAsync(PasswordResetEmailMessage message)
        {
            try
            {
                _logger.LogInformation($"📧 Sending password reset email to: {message.Email}");

                var emailMessage = new MimeMessage();

                // From
                emailMessage.From.Add(new MailboxAddress(
                    _configuration["Smtp:FromName"],
                    _configuration["Smtp:FromEmail"]
                ));

                // To
                emailMessage.To.Add(new MailboxAddress(message.UserName, message.Email));

                // Subject
                emailMessage.Subject = "BookNest - Password Reset Request";

                // Body
                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
                        <html>
                        <body style='font-family: Arial, sans-serif;'>
                            <h2>Password Reset Request</h2>
                            <p>Hello {message.UserName},</p>
                            <p>You requested to reset your password for your BookNest account.</p>
                            <p>Your reset token is: <strong>{message.Token}</strong></p>
                            <p>This token will expire at: <strong>{message.ExpiresAt.ToLocalTime():yyyy-MM-dd HH:mm:ss}</strong></p>
                            <p>If you did not request this, please ignore this email.</p>
                            <br/>
                            <p>Best regards,<br/>BookNest Team</p>
                        </body>
                        </html>
                    "
                };

                emailMessage.Body = bodyBuilder.ToMessageBody();

                // Send via SMTP
                using var client = new SmtpClient();

                await client.ConnectAsync(
                    _configuration["Smtp:Host"],
                    int.Parse(_configuration["Smtp:Port"] ?? "587"),
                    MailKit.Security.SecureSocketOptions.StartTls
                );

                await client.AuthenticateAsync(
                    _configuration["Smtp:Username"],
                    _configuration["Smtp:Password"]
                );

                await client.SendAsync(emailMessage);
                await client.DisconnectAsync(true);

                _logger.LogInformation($"✅ Email sent successfully to: {message.Email}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ Failed to send email to {message.Email}: {ex.Message}");
                throw;
            }
        }
    }
}