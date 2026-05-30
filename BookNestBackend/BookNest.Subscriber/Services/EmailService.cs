using BookNest.Subscriber.Models;
using MailKit.Net.Smtp;
using MimeKit;
using BookNest.Subscriber.Services.Interfaces;

namespace BookNest.Subscriber.Services
{
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;
        private readonly string _fromName;
        private readonly string _fromEmail;
        private readonly string _smtpHost;
        private readonly int _smtpPort;
        private readonly string _smtpUsername;
        private readonly string _smtpPassword;

        public EmailService(ILogger<EmailService> logger)
        {
            _logger = logger;
            _fromName = Environment.GetEnvironmentVariable("SMTP_FROM_NAME") ?? "";
            _fromEmail = Environment.GetEnvironmentVariable("SMTP_FROM_EMAIL") ?? "";
            _smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST") ?? "";
            _smtpPort = int.Parse(Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");
            _smtpUsername = Environment.GetEnvironmentVariable("SMTP_USERNAME") ?? "";
            _smtpPassword = Environment.GetEnvironmentVariable("SMTP_PASSWORD") ?? "";
        }

        public async Task SendPasswordResetEmailAsync(PasswordResetEmailMessage message)
        {
            try
            {
                _logger.LogInformation("Sending password reset email to: {Email}", message.Email);

                var emailMessage = new MimeMessage();

                emailMessage.From.Add(new MailboxAddress(_fromName, _fromEmail));

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

                await client.ConnectAsync(_smtpHost, _smtpPort, MailKit.Security.SecureSocketOptions.StartTls);

                await client.AuthenticateAsync(_smtpUsername, _smtpPassword);

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