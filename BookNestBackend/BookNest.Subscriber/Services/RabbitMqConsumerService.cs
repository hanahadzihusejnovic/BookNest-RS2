using BookNest.Subscriber.Models;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace BookNest.Subscriber.Services
{
    public class RabbitMqConsumerService : IRabbitMqConsumerService, IAsyncDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMqConsumerService> _logger;
        private readonly IServiceScopeFactory _serviceScopeFactory;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "password-reset-queue";

        public RabbitMqConsumerService(
            IConfiguration configuration,
            ILogger<RabbitMqConsumerService> logger,
            IServiceScopeFactory serviceScopeFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _serviceScopeFactory = serviceScopeFactory;
        }

        public async Task StartConsumingAsync()
        {
            try
            {
                _logger.LogInformation("🐰 Starting RabbitMQ Consumer...");

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

                _logger.LogInformation("✅ Connected to RabbitMQ. Listening on queue: {QueueName}", QueueName);

                var consumer = new AsyncEventingBasicConsumer(_channel);

                consumer.ReceivedAsync += async (sender, ea) =>
                {
                    try
                    {
                        var body = ea.Body.ToArray();
                        var messageJson = Encoding.UTF8.GetString(body);

                        _logger.LogInformation("📩 Received message: {MessageJson}", messageJson);

                        var message = JsonSerializer.Deserialize<PasswordResetEmailMessage>(messageJson);

                        if (message != null)
                        {
                            using var scope = _serviceScopeFactory.CreateScope();
                            var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                            await emailService.SendPasswordResetEmailAsync(message);

                            await _channel.BasicAckAsync(
                                deliveryTag: ea.DeliveryTag,
                                multiple: false
                            );

                            _logger.LogInformation("✅ Message processed and acknowledged");
                        }
                        else
                        {
                            _logger.LogWarning("⚠ Message deserialization returned null");

                            await _channel.BasicNackAsync(
                                deliveryTag: ea.DeliveryTag,
                                multiple: false,
                                requeue: false
                            );
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "❌ Error processing message");

                        if (_channel != null)
                        {
                            await _channel.BasicNackAsync(
                                deliveryTag: ea.DeliveryTag,
                                multiple: false,
                                requeue: true
                            );
                        }
                    }
                };

                await _channel.BasicConsumeAsync(
                    queue: QueueName,
                    autoAck: false,
                    consumer: consumer
                );

                _logger.LogInformation("🎧 RabbitMQ Consumer is now listening...");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to start RabbitMQ Consumer");
                throw;
            }
        }

        public async Task StopConsumingAsync()
        {
            _logger.LogInformation("🛑 Stopping RabbitMQ Consumer...");

            if (_channel != null)
            {
                await _channel.CloseAsync();
                await _channel.DisposeAsync();
                _channel = null;
            }

            if (_connection != null)
            {
                await _connection.CloseAsync();
                await _connection.DisposeAsync();
                _connection = null;
            }
        }

        public async ValueTask DisposeAsync()
        {
            await StopConsumingAsync();
        }
    }
}