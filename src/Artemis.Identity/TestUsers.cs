using Duende.IdentityServer.Test;
using System.Collections.Generic;
using System.Security.Claims;

public static class TestUsers
{
    public static List<TestUser> Users =>
        new List<TestUser>
        {
            new TestUser
            {
                SubjectId = "1",
                Username = "testuser",
                Password = "password",
                Claims =
                {
                    new Claim("name", "Test User"),
                    new Claim("website", "https://example.com")
                }
            }
        };
}