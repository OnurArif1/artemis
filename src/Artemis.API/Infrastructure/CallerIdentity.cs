using System.Security.Claims;

namespace Artemis.API.Infrastructure;

internal static class CallerIdentity
{
    /// <summary>
    /// Bearer JWT içinden giriş e-postasını okur; yoksa query parametresindeki e-postayı kullanır.
    /// </summary>
    internal static string? TryResolveLoginEmail(ClaimsPrincipal? user, string? queryEmail)
    {
        if (user?.Identity?.IsAuthenticated == true)
        {
            foreach (var type in new[]
                     {
                         "email",
                         ClaimTypes.Email,
                         ClaimTypes.Upn,
                         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
                         "unique_name",
                         "preferred_username",
                         // Bazı IdentityServer / JWT yapılandırmaları
                         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn",
                         "name",
                     })
            {
                var raw = user.FindFirstValue(type);
                if (LooksLikeEmail(raw))
                    return raw!.Trim();
            }

            var sub = user.FindFirstValue("sub");
            if (LooksLikeEmail(sub))
                return sub!.Trim();

            foreach (var claim in user.Claims)
            {
                if (LooksLikeEmail(claim.Value))
                    return claim.Value.Trim();
            }
        }

        return string.IsNullOrWhiteSpace(queryEmail) ? null : queryEmail.Trim();
    }

    private static bool LooksLikeEmail(string? value) =>
        !string.IsNullOrWhiteSpace(value) && value.Contains('@', StringComparison.Ordinal);
}
