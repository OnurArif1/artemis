using Artemis.API.Infrastructure;
using Artemis.API.Services;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ConnectionString'i configuration'dan oku
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// DbContext'i PostgreSQL ile bağla
builder.Services.AddDbContext<ArtemisDbContext>(options =>
{
    options.UseNpgsql(connectionString);

    if (builder.Environment.IsDevelopment())
    {
        options.EnableDetailedErrors();
        options.EnableSensitiveDataLogging();
    }
});

// Controller desteğini ekle
builder.Services.AddControllers();

// Services kayıtları
builder.Services.AddScoped<IRoomService, RoomService>();

// CORS (development için izin ver)
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
    {
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true)
            .AllowCredentials();
    });
});

// Identity Server Authentication
builder.Services
    .AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = "http://localhost:5095";
        options.RequireHttpsMetadata = false;
        options.Audience = "artemis.api";
    });

var app = builder.Build();

// Development ortamında veritabanı migrasyonlarını otomatik uygula
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ArtemisDbContext>();
    dbContext.Database.Migrate();
}

// HTTPS yönlendirme
app.UseHttpsRedirection();

// CORS
app.UseCors("DevCors");

app.UseAuthentication();
app.UseAuthorization();

// Controller route’larını aktif et
app.MapControllers();

app.Run();
