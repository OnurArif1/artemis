using Duende.IdentityServer.Models;
using Duende.IdentityServer.Services;
using Identity.Api.Models;
using Microsoft.AspNetCore.Identity;

namespace Identity.Api.Services;

public class ProfileService : IProfileService
{
    private readonly UserManager<ApplicationUser> _userManager;

    public ProfileService(UserManager<ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task GetProfileDataAsync(ProfileDataRequestContext context)
    {
        var user = await _userManager.GetUserAsync(context.Subject);
        if (user == null) return;

        var claims = context.Subject.Claims.ToList();

        // EMAIL claim'ini ekle (önemli!)
        if (!string.IsNullOrEmpty(user.Email))
        {
            // Email claim'i yoksa ekle
            if (!claims.Any(c => c.Type == "email" || c.Type == System.Security.Claims.ClaimTypes.Email))
            {
                claims.Add(new System.Security.Claims.Claim("email", user.Email));
                claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Email, user.Email));
            }
        }

        // FirstName ve LastName'i claim'lere ekle
        if (!string.IsNullOrEmpty(user.FirstName))
        {
            claims.Add(new System.Security.Claims.Claim("given_name", user.FirstName));
            claims.Add(new System.Security.Claims.Claim("first_name", user.FirstName));
        }

        if (!string.IsNullOrEmpty(user.LastName))
        {
            claims.Add(new System.Security.Claims.Claim("family_name", user.LastName));
            claims.Add(new System.Security.Claims.Claim("last_name", user.LastName));
        }

        // Name claim'ini oluştur (FirstName + LastName)
        if (!string.IsNullOrEmpty(user.FirstName) || !string.IsNullOrEmpty(user.LastName))
        {
            var fullName = $"{user.FirstName} {user.LastName}".Trim();
            if (!string.IsNullOrEmpty(fullName))
            {
                claims.Add(new System.Security.Claims.Claim("name", fullName));
            }
        }

        context.IssuedClaims = claims;
    }

    public async Task IsActiveAsync(IsActiveContext context)
    {
        var user = await _userManager.GetUserAsync(context.Subject);
        context.IsActive = user != null && user.IsActive;
    }
}

