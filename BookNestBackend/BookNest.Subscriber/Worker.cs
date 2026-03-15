using BookNest.Subscriber.Services;

namespace BookNest.Subscriber
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IRabbitMqConsumerService _rabbitMqConsumer;

        public Worker(ILogger<Worker> logger, IRabbitMqConsumerService rabbitMqConsumer)
        {
            _logger = logger;
            _rabbitMqConsumer = rabbitMqConsumer;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 BookNest.Subscriber Worker starting...");

            // Pokreni RabbitMQ Consumer
            await _rabbitMqConsumer.StartConsumingAsync();

            _logger.LogInformation("✅ BookNest.Subscriber Worker is running");

            // Keep running
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }

            _logger.LogInformation("🛑 BookNest.Subscriber Worker stopping...");
            await _rabbitMqConsumer.StopConsumingAsync();
        }
    }
}