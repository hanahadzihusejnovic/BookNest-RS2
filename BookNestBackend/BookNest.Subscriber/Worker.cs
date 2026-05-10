using BookNest.Subscriber.Services;
using BookNest.Subscriber.Services.Interfaces;

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
            _logger.LogInformation("BookNest.Subscriber Worker starting...");

            await StartConsumerSafelyAsync(
                "RabbitMqConsumerService",
                () => _rabbitMqConsumer.StartConsumingAsync(),
                stoppingToken);

            await StartConsumerSafelyAsync(
                "NotificationConsumerService",
                () => _notificationConsumer.StartConsumingAsync(),
                stoppingToken);

            _logger.LogInformation("All consumers started. Worker is running.");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }

            _logger.LogInformation("Worker stopping...");
            await _rabbitMqConsumer.StopConsumingAsync();
        }

        private async Task StartConsumerSafelyAsync(string consumerName, Func<Task> startAction, CancellationToken stoppingToken)
        {
            const int maxAttempts = 5;
            var attempt = 0;

            while (attempt < maxAttempts && !stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await startAction();
                    _logger.LogInformation("{ConsumerName} started successfully.", consumerName);
                    return;
                }
                catch (Exception ex)
                {
                    attempt++;
                    var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt));
                    _logger.LogError(ex, "{ConsumerName} failed to start. Attempt {Attempt}/{Max}. Retrying in {Delay}s.",
                        consumerName, attempt, maxAttempts, delay.TotalSeconds);

                    if (attempt >= maxAttempts)
                    {
                        _logger.LogCritical("{ConsumerName} could not start after {Max} attempts. This consumer is unavailable.", consumerName, maxAttempts);
                        return;
                    }

                    await Task.Delay(delay, stoppingToken);
                }
            }
        }
    }
}