using BookNest.Subscriber.Models;

namespace BookNest.Subscriber.Services.Interfaces
{
    public interface IEmailService
    {
        Task SendPasswordResetEmailAsync(PasswordResetEmailMessage message);
    }
}