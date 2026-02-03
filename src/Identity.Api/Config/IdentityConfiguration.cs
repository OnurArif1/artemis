using Duende.IdentityServer;
using Duende.IdentityServer.Models;
using Identity.Api.Models;

namespace Identity.Api.Config;

public static class IdentityConfiguration
{
    public static IEnumerable<IdentityResource> IdentityResources =>
        new IdentityResource[]
        {
            new IdentityResources.OpenId(),
            new IdentityResources.Profile(),
            new IdentityResources.Email(),
            new IdentityResource("roles", "User roles", new[] { "role" }),
            new IdentityResource("custom", "Custom claims", new[] { "first_name", "last_name" })
        };

    public static IEnumerable<ApiScope> ApiScopes =>
        new ApiScope[]
        {
            new ApiScope("artemis.api", "Artemis API"),
            new ApiScope("artemis.gateway", "Artemis Gateway")
        };

    public static IEnumerable<Client> Clients =>
        new Client[]
        {
            // Tek client - hem password hem client credentials
            new Client
            {
                ClientId = "artemis.client",
                ClientSecrets = { new Secret("artemis_secret".Sha256()) },
                AllowedGrantTypes = GrantTypes.ResourceOwnerPasswordAndClientCredentials,
                AllowedScopes = new List<string>
                {
                    IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServerConstants.StandardScopes.Profile,
                    IdentityServerConstants.StandardScopes.Email,
                    "roles",
                    "artemis.api"
                },
                AllowedCorsOrigins = new List<string>
                {
                    "http://localhost:5173",
                    "http://localhost:5174",
                    "http://localhost:5175",
                    "http://localhost:5176"
                },
                RequireConsent = false,
                AllowOfflineAccess = true
            }
        };

    public static IEnumerable<ApiResource> ApiResources =>
        new ApiResource[]
        {
            new ApiResource("artemis.api", "Artemis API")
            {
                Scopes = { "artemis.api" },
                UserClaims = { "role", "email", "name", "first_name", "last_name", "given_name", "family_name" }
            },
            new ApiResource("artemis.gateway", "Artemis Gateway")
            {
                Scopes = { "artemis.gateway" }
            }
        };
}
