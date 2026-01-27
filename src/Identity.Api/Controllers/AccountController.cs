using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Entities.Enums;
using Identity.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

        var email = request.Email.Trim();
        var existingUser = await _userManager.FindByEmailAsync(email);
        if (existingUser != null)
            return BadRequest(new { error = "Bu e-posta adresi zaten kullanılıyor." });

        var partyWithSameEmail = await _artemisDb.Parties
            .AnyAsync(p => p.Email != null && p.Email.ToLower() == email.ToLower(), ct);
        if (partyWithSameEmail)
            return BadRequest(new { error = "Bu e-posta adresi ile kayıtlı bir kişi zaten var." });

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
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

        var partyName = string.IsNullOrWhiteSpace(request.PartyName) ? email : request.PartyName.Trim();
        var party = new Party
        {
            PartyName = partyName,
            Email = email,
            PartyType = request.PartyType,
            IsBanned = request.IsBanned ?? false,
            DeviceId = request.DeviceId ?? 0,
            CreateDate = DateTime.UtcNow
        };
        await _artemisDb.Parties.AddAsync(party, ct);
        await _artemisDb.SaveChangesAsync(ct);

        return Ok(new { message = "Hesap oluşturuldu. Giriş yapabilirsiniz." });
    }
}
