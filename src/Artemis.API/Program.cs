using Microsoft.EntityFrameworkCore;
using Artemis.API.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// PostgreSQL bağlantısı için DbContext ekle
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", async (ApplicationDbContext dbContext) =>
{
    // Veritabanından veri çek
    var existingForecasts = await dbContext.WeatherForecasts.ToListAsync();
    
    if (existingForecasts.Any())
    {
        return Results.Ok(existingForecasts);
    }

    // Eğer veri yoksa yeni veri oluştur ve kaydet
    var newForecasts = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        {
            Date = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary = summaries[Random.Shared.Next(summaries.Length)]
        }).ToArray();

    await dbContext.WeatherForecasts.AddRangeAsync(newForecasts);
    await dbContext.SaveChangesAsync();

    return Results.Ok(newForecasts);
})
.WithName("GetWeatherForecast");

app.Run();