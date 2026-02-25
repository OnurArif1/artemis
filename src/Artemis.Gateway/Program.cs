using Ocelot.DependencyInjection;
using Ocelot.Middleware;

var builder = WebApplication.CreateBuilder(args);

var useOcelotJson = builder.Configuration.GetValue<bool>("USE_OCELOT_JSON", false);
var ocelotFile = (builder.Environment.IsDevelopment() && !useOcelotJson)
    ? "ocelot.Development.json" 
    : "ocelot.json";

builder.Configuration.AddJsonFile(ocelotFile, optional: false, reloadOnChange: true);
builder.Services.AddOcelot(builder.Configuration);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .SetIsOriginAllowed(_ => true)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

var app = builder.Build();

app.UseCors("AllowAll");

await app.UseOcelot();

app.Run();