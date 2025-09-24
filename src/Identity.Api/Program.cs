using Duende.IdentityServer;
using Duende.IdentityServer.EntityFramework.DbContexts;
using Duende.IdentityServer.EntityFramework.Mappers;
using Identity.Api.Config;
using Identity.Api.Data;
using Identity.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ConnectionString'i configuration'dan oku
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// Identity DbContext
builder.Services.AddDbContext<IdentityDbContext>(options =>
{
    options.UseNpgsql(connectionString);
    
    if (builder.Environment.IsDevelopment())
    {
        options.EnableDetailedErrors();
        options.EnableSensitiveDataLogging();
    }
});

// Identity Services
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<IdentityDbContext>()
.AddDefaultTokenProviders();

// Identity Server
builder.Services.AddIdentityServer(options =>
{
    options.Events.RaiseErrorEvents = true;
    options.Events.RaiseInformationEvents = true;
    options.Events.RaiseFailureEvents = true;
    options.Events.RaiseSuccessEvents = true;
    options.EmitStaticAudienceClaim = true;
})
.AddConfigurationStore(options =>
{
    options.ConfigureDbContext = b => b.UseNpgsql(connectionString, db => db.MigrationsAssembly("Identity.Api"));
})
.AddOperationalStore(options =>
{
    options.ConfigureDbContext = b => b.UseNpgsql(connectionString, db => db.MigrationsAssembly("Identity.Api"));
})
.AddAspNetIdentity<ApplicationUser>();

// CORS
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

var app = builder.Build();

// Development ortamında veritabanı migrasyonlarını otomatik uygula
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    
    // Identity DbContext
    var identityContext = services.GetRequiredService<IdentityDbContext>();
    identityContext.Database.Migrate();
    
    // Identity Server DbContexts
    var configContext = services.GetRequiredService<ConfigurationDbContext>();
    configContext.Database.Migrate();
    
    var persistedGrantContext = services.GetRequiredService<PersistedGrantDbContext>();
    persistedGrantContext.Database.Migrate();
    
    // Seed data
    await SeedDataAsync(services);
}

// HTTPS yönlendirme
app.UseHttpsRedirection();

// CORS
app.UseCors("DevCors");

// Identity Server
app.UseIdentityServer();

app.Run();

// Seed data method
async Task SeedDataAsync(IServiceProvider serviceProvider)
{
    var configContext = serviceProvider.GetRequiredService<ConfigurationDbContext>();
    var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
    var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

    // Seed Identity Resources
    if (!configContext.IdentityResources.Any())
    {
        foreach (var resource in IdentityConfiguration.IdentityResources)
        {
            configContext.IdentityResources.Add(resource.ToEntity());
        }
        await configContext.SaveChangesAsync();
    }

    // Seed API Scopes
    if (!configContext.ApiScopes.Any())
    {
        foreach (var scope in IdentityConfiguration.ApiScopes)
        {
            configContext.ApiScopes.Add(scope.ToEntity());
        }
        await configContext.SaveChangesAsync();
    }

    // Seed API Resources
    if (!configContext.ApiResources.Any())
    {
        foreach (var resource in IdentityConfiguration.ApiResources)
        {
            configContext.ApiResources.Add(resource.ToEntity());
        }
        await configContext.SaveChangesAsync();
    }

    // Seed Clients
    if (!configContext.Clients.Any())
    {
        foreach (var client in IdentityConfiguration.Clients)
        {
            configContext.Clients.Add(client.ToEntity());
        }
        await configContext.SaveChangesAsync();
    }

    // Seed Roles
    if (!await roleManager.RoleExistsAsync("Admin"))
    {
        await roleManager.CreateAsync(new IdentityRole("Admin"));
    }
    
    if (!await roleManager.RoleExistsAsync("User"))
    {
        await roleManager.CreateAsync(new IdentityRole("User"));
    }

    // Seed Admin User
    var adminUser = await userManager.FindByEmailAsync("admin@artemis.com");
    if (adminUser == null)
    {
        adminUser = new ApplicationUser
        {
            UserName = "admin@artemis.com",
            Email = "admin@artemis.com",
            FirstName = "Admin",
            LastName = "User",
            EmailConfirmed = true
        };
        
        var result = await userManager.CreateAsync(adminUser, "Admin123!");
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(adminUser, "Admin");
        }
    }
}