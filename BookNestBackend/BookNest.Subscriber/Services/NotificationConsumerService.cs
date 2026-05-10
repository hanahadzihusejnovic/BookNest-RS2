using BookNest.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace BookNest.Subscriber.Services
{
    public class NotificationConsumerService : IAsyncDisposable
    {
        private readonly ILogger<NotificationConsumerService> _logger;
        private readonly IHttpClientFactory _httpClientFactory;

        private IConnection? _connection;
        private IChannel? _channel;
        private const string QueueName = "notifications-queue";
        private const int MaxRetries = 5;

        public NotificationConsumerService(
            ILogger<NotificationConsumerService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _httpClientFactory = httpClientFactory;
        }

        public async Task StartConsumingAsync()
        {
            var factory = new ConnectionFactory
            {
                HostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST"),
                Port = int.Parse(Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? "5672"),
                UserName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME"),
                Password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
            };

            _connection = await factory.CreateConnectionAsync();
            _channel = await _connection.CreateChannelAsync();

            await _channel.QueueDeclareAsync(
                queue: QueueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null
            );

            var consumer = new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (sender, ea) =>
            {
                var retryCount = 0;
                var body = ea.Body.ToArray();
                var json = Encoding.UTF8.GetString(body);

                while (retryCount < MaxRetries)
                {
                    try
                    {
                        var message = JsonSerializer.Deserialize<NotificationMessage>(json);

                        if (message != null)
                        {
                            var httpClient = _httpClientFactory.CreateClient();
                            var content = new StringContent(json, Encoding.UTF8, "application/json");
                            var apiUrl = Environment.GetEnvironmentVariable("API_URL") ?? "http://localhost:7110";
                            var response = await httpClient.PostAsync($"{apiUrl}/api/Notification/send", content);

                            if (response.IsSuccessStatusCode)
                            {
                                _logger.LogInformation("Notification forwarded for user {UserId}", message.UserId);
                            }
                            else
                            {
                                _logger.LogWarning("API returned {StatusCode} for notification", response.StatusCode);
                            }

                            await _channel.BasicAckAsync(ea.DeliveryTag, false);
                            return;
                        }
                        else
                        {
                            _logger.LogWarning("Notification deserialization returned null. Discarding.");
                            await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false);
                            return;
                        }
                    }
                    catch (Exception ex)
                    {
                        retryCount++;
                        var delay = TimeSpan.FromSeconds(Math.Pow(2, retryCount));
                        _logger.LogWarning(ex, "Error processing notification. Attempt {Retry}/{Max}. Retrying in {Delay}s.",
                            retryCount, MaxRetries, delay.TotalSeconds);

                        if (retryCount >= MaxRetries)
                        {
                            _logger.LogError(ex, "Max retries reached. Discarding notification: {Message}", json);
                            await _channel!.BasicNackAsync(ea.DeliveryTag, false, requeue: false);
                            return;
                        }

                        await Task.Delay(delay);
                    }
                }
            };

            await _channel.BasicConsumeAsync(QueueName, autoAck: false, consumer: consumer);
            _logger.LogInformation("Notification Consumer listening on {Queue}", QueueName);
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null) { await _channel.CloseAsync(); await _channel.DisposeAsync(); }
            if (_connection != null) { await _connection.CloseAsync(); await _connection.DisposeAsync(); }
        }
    }
}