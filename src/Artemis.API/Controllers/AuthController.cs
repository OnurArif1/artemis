using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Artemis.API.Abstract;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAdmin _admin;
    private readonly IConfiguration _config;
    public AuthController(IAdmin admin, IConfiguration config)
    {
        _admin = admin;
        _config = config;
    }

    public record AdminLoginDto(string Email, string Password);

    [HttpPost("admin/login")]
    public async Task<IActionResult> AdminLogin([FromBody] AdminLoginDto dto)
    {
        var admin = (await _admin.GetAllAsync()).FirstOrDefault(a => a.Email == dto.Email && a.Password == dto.Password);
        if (admin == null) return Unauthorized();

        var key = _config["Jwt:Key"] ?? "dev_secret_please_change";
        var issuer = _config["Jwt:Issuer"] ?? "Artemis";
        var audience = _config["Jwt:Audience"] ?? "ArtemisAudience";

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, admin.Email),
            new Claim("adminId", admin.Id.ToString()),
            new Claim(ClaimTypes.Role, "Admin")
        };

        var creds = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds
        );

        return Ok(new { token = new JwtSecurityTokenHandler().WriteToken(token) });
    }
}


