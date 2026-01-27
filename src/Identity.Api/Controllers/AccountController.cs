using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Entities.Enums;
using Identity.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace Identity.Api.Controllers;

[ApiController]
[Route("account")]
[AllowAnonymous]
public class AccountController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ArtemisDbContext _artemisDb;

    public AccountController(UserManager<ApplicationUser> userManager, ArtemisDbContext artemisDb)
    {
        _userManager = userManager;
        _artemisDb = artemisDb;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            return BadRequest(new { error = "E-posta ve şifre gerekli." });

        var existing = await _userManager.FindByEmailAsync(request.Email);
        if (existing != null)
            return BadRequest(new { error = "Bu e-posta adresi zaten kullanılıyor." });

        var user = new ApplicationUser
        {
            UserName = request.Email.Trim(),
            Email = request.Email.Trim(),
            EmailConfirmed = true,
            LockoutEnabled = false,
            IsAdminPanelUser = false
        };

        var createResult = await _userManager.CreateAsync(user, request.Password);
        if (!createResult.Succeeded)
        {
            var first = createResult.Errors.FirstOrDefault();
            var msg = first != null ? first.Description : "Kayıt oluşturulamadı.";
            return BadRequest(new { error = msg });
        }

        await _userManager.AddToRoleAsync(user, "User");

        var party = new Party
        {
            PartyName = request.Email.Trim(),
            PartyType = PartyType.Person,
            IsBanned = false,
            DeviceId = 0,
            CreateDate = DateTime.UtcNow
        };
        await _artemisDb.Parties.AddAsync(party, ct);
        await _artemisDb.SaveChangesAsync(ct);

        return Ok(new { message = "Hesap oluşturuldu. Giriş yapabilirsiniz." });
    }
}
