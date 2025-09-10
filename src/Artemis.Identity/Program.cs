// filepath: c:\Users\Mert\Documents\Artemis\src\Artemis.Identity\Program.cs
// ...existing code...
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddIdentityServer()
    .AddInMemoryClients(Config.Clients)
    .AddInMemoryIdentityResources(Config.IdentityResources)
    .AddInMemoryApiScopes(Config.ApiScopes)
    .AddTestUsers(TestUsers.Users);

var app = builder.Build();

app.UseIdentityServer();

app.Run();

