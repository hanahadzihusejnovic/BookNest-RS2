using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace BookNest.Services.MessageQueue
{
    public class RabbitMqPublisher : IRabbitMqPublisher, IAsyncDisposable
    {
        private readonly ILogger<RabbitMqPublisher> _logger;
        private IConnection? _connection;
        private IChannel? _channel;
        private readonly SemaphoreSlim _semaphore = new(1, 1);

        public RabbitMqPublisher(ILogger<RabbitMqPublisher> logger)
        {
            _logger = logger;
        }

        private async Task EnsureConnectedAsync()
        {
            if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
                return;

            await _semaphore.WaitAsync();
            try
            {
                if (_connection != null && _connection.IsOpen && _channel != null && _channel.IsOpen)
                    return;

                var factory = new ConnectionFactory
                {
                    HostName = Environment.GetEnvironmentVariable("RABBITMQ_HOST"),
                    Port = int.Parse(Environment.GetEnvironmentVariable("RABBITMQ_PORT") ?? "5672"),
                    UserName = Environment.GetEnvironmentVariable("RABBITMQ_USERNAME"),
                    Password = Environment.GetEnvironmentVariable("RABBITMQ_PASSWORD")
                };

                _connection = await factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();

                _logger.LogInformation("RabbitMQ connection established.");
            }
            finally
            {
                _semaphore.Release();
            }
        }

        public async Task PublishAsync<T>(string queueName, T message)
        {
            try
            {
                await EnsureConnectedAsync();

                await _channel!.QueueDeclareAsync(
                    queue: queueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null
                );

                var messageJson = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(messageJson);

                await _channel.BasicPublishAsync(
                    exchange: string.Empty,
                    routingKey: queueName,
                    body: body
                );

                _logger.LogInformation("Message published to queue: {QueueName}", queueName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish message to queue {QueueName}", queueName);
                throw;
            }
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null) { await _channel.CloseAsync(); await _channel.DisposeAsync(); }
            if (_connection != null) { await _connection.CloseAsync(); await _connection.DisposeAsync(); }
        }
    }
}