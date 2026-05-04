using BookNest.Subscriber.Services;

namespace BookNest.Subscriber
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IRabbitMqConsumerService _rabbitMqConsumer;
        private readonly NotificationConsumerService _notificationConsumer;

        public Worker(
            ILogger<Worker> logger,
            IRabbitMqConsumerService rabbitMqConsumer,
            NotificationConsumerService notificationConsumer)
        {
            _logger = logger;
            _rabbitMqConsumer = rabbitMqConsumer;
            _notificationConsumer = notificationConsumer;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 BookNest.Subscriber Worker starting...");

            await _rabbitMqConsumer.StartConsumingAsync();
            await _notificationConsumer.StartConsumingAsync();

            _logger.LogInformation("✅ All consumers running");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }

            await _rabbitMqConsumer.StopConsumingAsync();
        }
    }
}