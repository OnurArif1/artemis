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

builder.Services
    .AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = "http://localhost:5095";
        options.RequireHttpsMetadata = false;
        options.Audience = "artemis.api";
    });

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<ArtemisDbContext>();
    dbContext.Database.Migrate();
    
    // // Tek seferlik yasak kelime ekleme - kullanmak için yorumu kaldırın
    // var forbiddenWordsCreator = new ForbiddenWordsCreator(dbContext);
    // var wordsToAdd = new List<string> { "kelime1", "kelime2", "kelime3" }; // Buraya eklemek istediğiniz kelimeleri yazın
    // forbiddenWordsCreator.SaveExpandedForbiddenWordsAsync(wordsToAdd).GetAwaiter().GetResult();
}

app.UseHttpsRedirection();

app.UseCors("DevCors");
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
app.Urls.Add("http://0.0.0.0:5094");

app.Run();
