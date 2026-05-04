using BookNest.Subscriber;
using BookNest.Subscriber.Services;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddSingleton<IRabbitMqConsumerService, RabbitMqConsumerService>();

builder.Services.AddSingleton<NotificationConsumerService>();
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();