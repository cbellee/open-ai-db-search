using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing.Constraints;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace backend
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateSlimBuilder(args);

            builder.Services.AddEndpointsApiExplorer();
            Console.WriteLine(builder.Configuration.GetConnectionString("DefaultConnection"));

            builder.Services.AddDbContext<SqldbAdventureworksContext>();
            builder.Services.Configure<RouteOptions>(options => options.SetParameterPolicy<RegexInlineRouteConstraint>("regex"));
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            var app = builder.Build();

            app.UseSwagger();
            app.UseSwaggerUI();

            app.MapGet("/products", async Task<List<Product>> ([FromQuery] string? color, SqldbAdventureworksContext db) =>
            {
                if (color.IsNullOrEmpty())
                {
                    return await db.Products.ToListAsync();
                }

                var products = await db.Products
                    .Where(p => p.Color == color)
                    .ToListAsync();

                if (products.Count <= 0)
                {
                    return new List<Product>();
                }

                return products;
            });

            app.Run();
        }
    }
}
