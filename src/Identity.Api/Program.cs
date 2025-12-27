using Duende.IdentityServer;
using Duende.IdentityServer.EntityFramework.DbContexts;
using Duende.IdentityServer.EntityFramework.Mappers;
using Duende.IdentityServer.Services;
using Identity.Api.Config;
using Identity.Api.Data;
using Identity.Api.Models;
using Identity.Api.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Artemis.API.Infrastructure;
using Artemis.API.Entities;
using Artemis.API.Entities.Enums;

var builder = WebApplication.CreateBuilder(args);

// ConnectionString'i configuration'dan oku
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var artemisConnectionString = builder.Configuration.GetConnectionString("ArtemisConnection") 
    ?? "Host=65.21.157.56;Port=5432;Database=artemisdb;Username=postgres;Password=xct41troamber65";

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

// Artemis DbContext (Party oluşturmak için)
builder.Services.AddDbContext<ArtemisDbContext>(options =>
{
    options.UseNpgsql(artemisConnectionString);
    
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

// Profile Service (custom claims için)
builder.Services.AddTransient<IProfileService, ProfileService>();

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

// Controllers
builder.Services.AddControllers();

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

// Routing
app.UseRouting();

// Identity Server
app.UseIdentityServer();

// Controllers
app.MapControllers();

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
            EmailConfirmed = true,
            IsAdminPanelUser = true // Admin panelden kayıt olan kullanıcı
        };
        
        var result = await userManager.CreateAsync(adminUser, "Admin123!");
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(adminUser, "Admin");
        }
    }
    else
    {
        // Mevcut admin kullanıcısını güncelle
        if (!adminUser.IsAdminPanelUser)
        {
            adminUser.IsAdminPanelUser = true;
            await userManager.UpdateAsync(adminUser);
        }
    }
}