
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using BookNest.Services.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using AutoMapper;
using BookNest.Services.Mapping;
using System.Text.Json.Serialization;
using System.ComponentModel;
using BookNest.Services.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;
using BookNest.Infrastructure.Services;
using BookNest.Services.MessageQueue;

namespace BookNest.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            //Omoguci HTTP za development (Flutter)
            if (builder.Environment.IsDevelopment())
            {
                builder.WebHost.UseUrls("http://localhost:7110", "https://localhost:7111");
            }

            // ----- CORS CONFIGURATION (za Flutter) -----
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowFlutter", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });
            });

            // ===== JWT SETTINGS CONFIGURATION =====
            builder.Services.Configure<JwtSettings>(
                builder.Configuration.GetSection("JwtSettings"));

            var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>();

            // ===== JWT AUTHENTICATION =====
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
            });

            builder.Services.AddAuthorization();

            // Add services to the container.

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
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            builder.Services.AddControllers();

            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

            // ===== SWAGGER WITH JWT SUPPORT =====
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "BookNest API", Version = "v1" });

                // Define JWT security scheme
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

            // CORS
            app.UseCors("AllowFlutter");

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }
            
            // DEVELOPMENT (ne HTTPS)
            if (!app.Environment.IsDevelopment())
            {
                app.UseHttpsRedirection();
            }

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
