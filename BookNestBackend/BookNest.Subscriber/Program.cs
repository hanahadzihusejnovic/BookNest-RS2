using BookNest.Subscriber;
using BookNest.Subscriber.Services;
using BookNest.Subscriber.Services.Interfaces;
using DotNetEnv;

Env.Load();

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddSingleton<IRabbitMqConsumerService, RabbitMqConsumerService>();

builder.Services.AddSingleton<NotificationConsumerService>();
builder.Services.AddHostedService<Worker>();

builder.Services.AddHttpClient();

var host = builder.Build();
host.Run();