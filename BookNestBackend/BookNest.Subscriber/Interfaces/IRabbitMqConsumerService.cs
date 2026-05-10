namespace BookNest.Subscriber.Services.Interfaces
{
    public interface IRabbitMqConsumerService
    {
        Task StartConsumingAsync();
        Task StopConsumingAsync();
    }
}