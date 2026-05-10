using BookNest.Subscriber.Models;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using BookNest.Subscriber.Services.Interfaces;

namespace BookNest.Subscriber.Services
{
    public class RabbitMqConsumerService : IRabbitMqConsumerService, IAsyncDisposable
    {
        private readonly ILogger<RabbitMqConsumerService> _logger;
        private readonly IServiceScopeFactory _serviceScopeFactory;

        private IConnection? _connection;
        private IChannel? _channel;

        private const string QueueName = "password-reset-queue";
        private const int MaxRetries = 5;

        public RabbitMqConsumerService(
            ILogger<RabbitMqConsumerService> logger,
            IServiceScopeFactory serviceScopeFactory)
        {
            _logger = logger;
            _serviceScopeFactory = serviceScopeFactory;
        }

        public async Task StartConsumingAsync()
        {
            try
            {
                _logger.LogInformation("Starting RabbitMQ Consumer...");

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

                _logger.LogInformation("Connected to RabbitMQ. Listening on queue: {QueueName}", QueueName);

                var consumer = new AsyncEventingBasicConsumer(_channel);

                consumer.ReceivedAsync += async (sender, ea) =>
                {
                    var retryCount = 0;
                    var body = ea.Body.ToArray();
                    var messageJson = Encoding.UTF8.GetString(body);

                    while (retryCount < MaxRetries)
                    {
                        try
                        {
                            var message = JsonSerializer.Deserialize<PasswordResetEmailMessage>(messageJson);

                            if (message != null)
                            {
                                using var scope = _serviceScopeFactory.CreateScope();
                                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                                await emailService.SendPasswordResetEmailAsync(message);

                                await _channel.BasicAckAsync(ea.DeliveryTag, false);
                                _logger.LogInformation("Message processed and acknowledged.");
                                return;
                            }
                            else
                            {
                                _logger.LogWarning("Message deserialization returned null. Discarding.");
                                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false);
                                return;
                            }
                        }
                        catch (Exception ex)
                        {
                            retryCount++;
                            var delay = TimeSpan.FromSeconds(Math.Pow(2, retryCount));
                            _logger.LogWarning(ex, "Error processing message. Attempt {Retry}/{Max}. Retrying in {Delay}s.",
                                retryCount, MaxRetries, delay.TotalSeconds);

                            if (retryCount >= MaxRetries)
                            {
                                _logger.LogError(ex, "Max retries reached. Discarding message: {Message}", messageJson);
                                await _channel!.BasicNackAsync(ea.DeliveryTag, false, requeue: false);
                                return;
                            }

                            await Task.Delay(delay);
                        }
                    }
                };

                await _channel.BasicConsumeAsync(
                    queue: QueueName,
                    autoAck: false,
                    consumer: consumer
                );

                _logger.LogInformation("RabbitMQ Consumer is now listening...");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start RabbitMQ Consumer. Worker will continue but this queue is not being consumed.");
                throw;
            }
        }

        public async Task StopConsumingAsync()
        {
            _logger.LogInformation("Stopping RabbitMQ Consumer...");

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