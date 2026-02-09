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
