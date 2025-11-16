
using BookNest.Services.Database;
using BookNest.Services.Interfaces;
using BookNest.Services.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using AutoMapper;
using BookNest.Services.Mapping;
using System.Text.Json.Serialization;
using System.ComponentModel;

namespace BookNest.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.

            builder.Services.AddScoped<IBookService, BookService>();
            builder.Services.AddScoped<IAuthorService, AuthorService>();
            builder.Services.AddScoped<ICategoryService, CategoryService>();
            builder.Services.AddScoped<IOrganizerService, OrganizerService>();
            builder.Services.AddScoped<IEventCategoryService, EventCategoryService>();
            builder.Services.AddScoped<IEventService, EventService>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<ICartService, CartService>();

            builder.Services.AddAutoMapper(cfg => { },
                typeof(BookProfile).Assembly,
                typeof(AuthorProfile).Assembly,
                typeof(CategoryProfile).Assembly,
                typeof(EventCategoryProfile).Assembly,
                typeof(OrganizerProfile).Assembly,
                typeof(EventProfile).Assembly,
                typeof(UserProfile).Assembly,
                typeof(CartProfile).Assembly,
                typeof(RoleProfile).Assembly);

            builder.Services.AddDbContext<BookNestDbContext>(options => 
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            builder.Services.AddControllers();

            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
