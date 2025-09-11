using Artemis.API.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ConnectionString'i configuration'dan oku
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// DbContext'i PostgreSQL ile bağla
builder.Services.AddDbContext<ApplicationDbContext>(options =>
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

var app = builder.Build();

// Development ortamında veritabanı migrasyonlarını otomatik uygula
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    dbContext.Database.Migrate();
}

// HTTPS yönlendirme
app.UseHttpsRedirection();

// Controller route’larını aktif et
app.MapControllers();

app.Run();
