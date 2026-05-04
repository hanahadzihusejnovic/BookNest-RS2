using BookNest.Model.Messages;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace BookNest.Subscriber.Services
{
    public class NotificationConsumerService : IAsyncDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<NotificationConsumerService> _logger;
        private readonly HttpClient _httpClient;

        private IConnection? _connection;
        private IChannel? _channel;
        private const string QueueName = "notifications-queue";

        public NotificationConsumerService(
            IConfiguration configuration,
            ILogger<NotificationConsumerService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = new HttpClient();
        }

        public async Task StartConsumingAsync()
        {
            var factory = new ConnectionFactory
            {
                HostName = _configuration["RabbitMQ:Host"],
                Port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672"),
                UserName = _configuration["RabbitMQ:Username"],
                Password = _configuration["RabbitMQ:Password"]
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
                try
                {
                    var body = ea.Body.ToArray();
                    var json = Encoding.UTF8.GetString(body);
                    var message = JsonSerializer.Deserialize<NotificationMessage>(json);

                    if (message != null)
                    {
                        // Pošalji na API koji će proslijediti kroz SignalR
                        var content = new StringContent(json, Encoding.UTF8, "application/json");
                        var apiUrl = _configuration["ApiUrl"] ?? "http://localhost:7110";
                        var response = await _httpClient.PostAsync($"{apiUrl}/api/Notification/send", content);

                        if (response.IsSuccessStatusCode)
                        {
                            _logger.LogInformation("✅ Notification forwarded to API for user {UserId}", message.UserId);
                        }
                        else
                        {
                            _logger.LogWarning("⚠️ API returned {StatusCode}", response.StatusCode);
                        }

                        await _channel.BasicAckAsync(ea.DeliveryTag, false);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error processing notification");
                    await _channel!.BasicNackAsync(ea.DeliveryTag, false, true);
                }
            };

            await _channel.BasicConsumeAsync(QueueName, autoAck: false, consumer: consumer);
            _logger.LogInformation("🎧 Notification Consumer listening on {Queue}", QueueName);
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null) { await _channel.CloseAsync(); await _channel.DisposeAsync(); }
            if (_connection != null) { await _connection.CloseAsync(); await _connection.DisposeAsync(); }
        }
    }
}