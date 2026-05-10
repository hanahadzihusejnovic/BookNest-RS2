using BookNest.Subscriber.Models;
using MailKit.Net.Smtp;
using MimeKit;
using BookNest.Subscriber.Services.Interfaces;

namespace BookNest.Subscriber.Services
{
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;

        public EmailService(ILogger<EmailService> logger)
        {
            _logger = logger;
        }

        public async Task SendPasswordResetEmailAsync(PasswordResetEmailMessage message)
        {
            try
            {
                _logger.LogInformation("Sending password reset email to: {Email}", message.Email);

                var emailMessage = new MimeMessage();

                emailMessage.From.Add(new MailboxAddress(
                    Environment.GetEnvironmentVariable("SMTP_FROM_NAME"),
                    Environment.GetEnvironmentVariable("SMTP_FROM_EMAIL")
                ));

                emailMessage.To.Add(new MailboxAddress(message.UserName, message.Email));

                emailMessage.Subject = "BookNest - Password Reset Request";

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

                using var client = new SmtpClient();

                await client.ConnectAsync(
                    Environment.GetEnvironmentVariable("SMTP_HOST"),
                    int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587"),
                    MailKit.Security.SecureSocketOptions.StartTls
                );

                await client.AuthenticateAsync(
                    Environment.GetEnvironmentVariable("SMTP_USERNAME"),
                    Environment.GetEnvironmentVariable("SMTP_PASSWORD")
                );

                await client.SendAsync(emailMessage);
                await client.DisconnectAsync(true);

                _logger.LogInformation("Email sent successfully to: {Email}", message.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to {Email}", message.Email);
                throw;
            }
        }
    }
}