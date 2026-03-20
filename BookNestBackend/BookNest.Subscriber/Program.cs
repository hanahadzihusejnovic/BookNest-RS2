using BookNest.Subscriber;
using BookNest.Subscriber.Services;

var builder = Host.CreateApplicationBuilder(args);

// Registracija servisa
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddSingleton<IRabbitMqConsumerService, RabbitMqConsumerService>();
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();