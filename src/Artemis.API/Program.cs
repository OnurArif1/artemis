using Artemis.API.Data;
using Artemis.API.Repositories;
using Artemis.API.Abstract;
using src.Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

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

// DI - Repositories
builder.Services.AddScoped<IComment, CommentRepository>();
builder.Services.AddScoped<IPost, PostRepository>();
builder.Services.AddScoped<IAdmin, AdminRepository>();

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
    var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
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
