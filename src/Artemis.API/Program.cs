using Artemis.API.Entities;
using Artemis.API.Hubs;
using Artemis.API.Infrastructure;
using Artemis.API.Services;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSignalR();
builder.Services.AddCors();

builder.Services.AddScoped<IRoomService, RoomService>();
builder.Services.AddScoped<IPartyService, PartyService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ITopicService, TopicService>();
builder.Services.AddScoped<IHashtagService, HashtagService>();
builder.Services.AddScoped<IRoomHashtagMapService, RoomHashtagMapService>();
builder.Services.AddScoped<ICategoryHashtagMapService, CategoryHashtagMapService>();
builder.Services.AddScoped<ITopicHashtagMapService, TopicHashtagMapService>();
builder.Services.AddScoped<IMentionService, MentionService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<ICommentService, CommentService>();
builder.Services.AddScoped<IInterestService, InterestService>();
builder.Services.AddScoped<IPartyInterestService, PartyInterestService>();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<ArtemisDbContext>(options =>
{
    options.UseNpgsql(connectionString);

    if (builder.Environment.IsDevelopment())
    {
        options.EnableDetailedErrors();
        options.EnableSensitiveDataLogging();
    }
});

builder.Services.AddControllers();
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

var identityAuthority = builder.Configuration["IdentityAuthority"] 
    ?? builder.Configuration["IDENTITY_AUTHORITY"] 
    ?? "http://identity-api:5095";

builder.Services
    .AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = identityAuthority;
        options.RequireHttpsMetadata = false;
        options.Audience = "artemis.api";
    });

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ArtemisDbContext>();
    dbContext.Database.Migrate();
    await SeedInterestsAsync(dbContext);
}

app.UseHttpsRedirection();

app.UseCors("DevCors");
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");

// URL'ler ASPNETCORE_URLS environment variable'ından alınır
// Docker ortamında docker-compose.yml'de ayarlanmıştır
// Development ortamında launchSettings.json'dan alınır
app.Run();

async Task SeedInterestsAsync(ArtemisDbContext context)
{
    if (await context.Interests.AnyAsync())
    {
        return; // Seed data zaten var
    }

    var interests = new List<Interest>
    {
        new Interest { Name = "Sports" },
        new Interest { Name = "Fitness" },
        new Interest { Name = "Hiking" },
        new Interest { Name = "Coffee" },
        new Interest { Name = "Food" },
        new Interest { Name = "Cooking" },
        new Interest { Name = "Music" },
        new Interest { Name = "Concerts" },
        new Interest { Name = "Art" },
        new Interest { Name = "Photography" },
        new Interest { Name = "Travel" },
        new Interest { Name = "Books" },
        new Interest { Name = "Movies" },
        new Interest { Name = "Gaming" },
        new Interest { Name = "Tech" },
        new Interest { Name = "Business" },
        new Interest { Name = "Meditation" },
        new Interest { Name = "Yoga" },
        new Interest { Name = "Dancing" },
        new Interest { Name = "Languages" },
        new Interest { Name = "Volunteering" },
        new Interest { Name = "Nature" },
        new Interest { Name = "Animals" },
        new Interest { Name = "Outdoor" }
    };

    await context.Interests.AddRangeAsync(interests);
    await context.SaveChangesAsync();
}
