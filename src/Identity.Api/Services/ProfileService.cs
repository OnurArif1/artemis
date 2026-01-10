using Duende.IdentityServer.Models;
using Duende.IdentityServer.Services;
using Identity.Api.Models;
using Microsoft.AspNetCore.Identity;
using System.Security.Claims;

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

        if (user != null)
        {
            var claims = context.Subject.Claims.ToList();

            // Custom claims ekle
            if (!string.IsNullOrEmpty(user.FirstName))
            {
                claims.Add(new Claim("first_name", user.FirstName));
                claims.Add(new Claim("given_name", user.FirstName));
            }

            if (!string.IsNullOrEmpty(user.LastName))
            {
                claims.Add(new Claim("last_name", user.LastName));
                claims.Add(new Claim("family_name", user.LastName));
            }

            // Kullanıcı rollerini ekle
            var roles = await _userManager.GetRolesAsync(user);
            foreach (var role in roles)
            {
                claims.Add(new Claim("role", role));
            }

            context.IssuedClaims = claims;
        }
    }

    public async Task IsActiveAsync(IsActiveContext context)
    {
        var user = await _userManager.GetUserAsync(context.Subject);

        if (user != null)
        {
            context.IsActive = user.IsActive && !user.LockoutEnabled;
        }
        else
        {
            context.IsActive = false;
        }
    }
}