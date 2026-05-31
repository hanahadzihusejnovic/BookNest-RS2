using BookNest.API.Hubs;
using BookNest.Services.Seeder;
using BookNest.API.Middleware;
using BookNest.Infrastructure.Services;
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using BookNest.Services.Mapping;
using BookNest.Services.MessageQueue;
using BookNest.Services.Security;
using BookNest.Services.Services;
using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

namespace BookNest.API
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            Env.Load();

            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowFlutter", policy =>
                {
                    policy.WithOrigins(
                            "http://10.0.2.2:7110",
                            "http://localhost:7110")
                          .AllowAnyMethod()
                          .AllowAnyHeader()
                          .AllowCredentials();
                });
            });

            builder.Services.Configure<JwtSettings>(options =>
            {
                options.SecretKey = Environment.GetEnvironmentVariable("JWT_SECRET")!;
                options.Issuer = Environment.GetEnvironmentVariable("JWT_ISSUER")!;
                options.Audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE")!;
                options.ExpirationMinutes = int.Parse(Environment.GetEnvironmentVariable("JWT_EXPIRATION_MINUTES")!);
            });

            var jwtSettings = new JwtSettings
            {
                SecretKey = Environment.GetEnvironmentVariable("JWT_SECRET")!,
                Issuer = Environment.GetEnvironmentVariable("JWT_ISSUER")!,
                Audience = Environment.GetEnvironmentVariable("JWT_AUDIENCE")!,
                ExpirationMinutes = int.Parse(Environment.GetEnvironmentVariable("JWT_EXPIRATION_MINUTES")!)
            };

            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtSettings.Issuer,
                    ValidAudience = jwtSettings.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(jwtSettings.SecretKey))
                };
                options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        var accessToken = context.Request.Query["access_token"];
                        if (!string.IsNullOrEmpty(accessToken) &&
                            context.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                        {
                            context.Token = accessToken;
                        }
                        return Task.CompletedTask;
                    }
                };
            });

            builder.Services.AddAuthorization();

            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IBookService, BookService>();
            builder.Services.AddScoped<IAuthorService, AuthorService>();
            builder.Services.AddScoped<ICategoryService, CategoryService>();
            builder.Services.AddScoped<IOrganizerService, OrganizerService>();
            builder.Services.AddScoped<IEventCategoryService, EventCategoryService>();
            builder.Services.AddScoped<IEventService, EventService>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<ICartService, CartService>();
            builder.Services.AddScoped<IOrderService, OrderService>();
            builder.Services.AddScoped<IFavoriteService, FavoriteService>();
            builder.Services.AddScoped<ITBRListService, TBRListService>();
            builder.Services.AddScoped<IReviewService, ReviewService>();
            builder.Services.AddScoped<IEventReservationService, EventReservationService>();
            builder.Services.AddScoped<IImageService, AzureBlobImageService>();
            builder.Services.AddScoped<IDashboardService, DashboardService>();
            builder.Services.AddScoped<ICityService, CityService>();
            builder.Services.AddScoped<ICountryService, CountryService>();
            builder.Services.AddScoped<INotificationService, NotificationService>();

            builder.Services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();
            builder.Services.AddSingleton<IRabbitMqPublisher, RabbitMqPublisher>();

            builder.Services.AddAutoMapper(cfg => { },
                typeof(BookProfile).Assembly,
                typeof(AuthorProfile).Assembly,
                typeof(CategoryProfile).Assembly,
                typeof(EventCategoryProfile).Assembly,
                typeof(OrganizerProfile).Assembly,
                typeof(EventProfile).Assembly,
                typeof(UserProfile).Assembly,
                typeof(CartProfile).Assembly,
                typeof(RoleProfile).Assembly,
                typeof(OrderProfile).Assembly,     
                typeof(FavoriteProfile).Assembly,
                typeof(TBRListProfile).Assembly,  
                typeof(ReviewProfile).Assembly,
                typeof(EventReservationProfile).Assembly);     


            builder.Services.AddDbContext<BookNestDbContext>(options => 
                options.UseSqlServer(Environment.GetEnvironmentVariable("DB_CONNECTION")));

            builder.Services.AddControllers();

            builder.Services.AddSignalR();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "BookNest API", Version = "v1" });
                
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below.",
                    Name = "Authorization",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = "Bearer"
                });

                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        new string[] {}
                    }
                });
            });

            var app = builder.Build();

            app.UseCors("AllowFlutter");

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }
            

            app.UseMiddleware<ExceptionMiddleware>();

            app.UseMiddleware<TokenBlacklistMiddleware>();

            app.UseAuthentication();

            app.UseAuthorization();

            app.MapControllers();

            app.MapHub<NotificationHub>("/hubs/notifications");

            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<BookNestDbContext>();
                db.Database.Migrate();
            }

            using var seedScope = app.Services.CreateScope();
            var seedDb = seedScope.ServiceProvider.GetRequiredService<BookNestDbContext>();
            var seedHasher = seedScope.ServiceProvider.GetRequiredService<IPasswordHasher>();
            await DatabaseSeeder.SeedAsync(seedDb, seedHasher);

            app.Run();
        }
    }
}
