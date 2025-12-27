using Identity.Api.Models;
using Identity.Api.ViewModels;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Artemis.API.Infrastructure;
using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Microsoft.EntityFrameworkCore;

namespace Identity.Api.Controllers;

[ApiController]
[Route("account")]
public class AccountController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ILogger<AccountController> _logger;
    private readonly ArtemisDbContext _artemisDbContext;

    public AccountController(
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        ILogger<AccountController> logger,
        ArtemisDbContext artemisDbContext)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _logger = logger;
        _artemisDbContext = artemisDbContext;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterViewModel model)
    {
        if (model == null)
        {
            return BadRequest(new { message = "Request body boş olamaz" });
        }

        if (!ModelState.IsValid)
        {
            var errors = ModelState
                .Where(x => x.Value?.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value?.Errors.Select(e => e.ErrorMessage).ToArray()
                );
            _logger.LogWarning("Register validation failed: {Errors}", string.Join(", ", errors.SelectMany(e => e.Value ?? Array.Empty<string>())));
            return BadRequest(new { message = "Geçersiz veri", errors });
        }

        try
        {
            // Kullanıcı zaten var mı kontrol et
            var existingUser = await _userManager.FindByEmailAsync(model.Email);
            if (existingUser != null)
            {
                return BadRequest(new { message = "Bu e-posta adresi zaten kullanılıyor" });
            }

            // Yeni kullanıcı oluştur
            var user = new ApplicationUser
            {
                UserName = model.Email,
                Email = model.Email,
                FirstName = model.FirstName,
                LastName = model.LastName,
                EmailConfirmed = true, // Development için otomatik onaylı
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, model.Password);

            if (!result.Succeeded)
            {
                var errors = result.Errors.Select(e => e.Description);
                return BadRequest(new { message = "Kullanıcı oluşturulamadı", errors });
            }

            // Varsayılan olarak User rolüne ekle
            var userRole = await _roleManager.FindByNameAsync("User");
            if (userRole != null)
            {
                await _userManager.AddToRoleAsync(user, "User");
            }
            else
            {
                // User rolü yoksa oluştur
                await _roleManager.CreateAsync(new IdentityRole("User"));
                await _userManager.AddToRoleAsync(user, "User");
            }

            // Party oluştur (UI kullanıcıları için) - EMAIL kullan (en güvenilir)
            int? partyId = null;
            try
            {
                // Email'e göre Party ara (en güvenilir yöntem)
                var existingParty = await _artemisDbContext.Parties
                    .FirstOrDefaultAsync(p => p.PartyName == model.Email && p.PartyType == PartyType.Person);

                if (existingParty == null)
                {
                    // Email ile Party oluştur
                    var newParty = new Person
                    {
                        PartyName = model.Email, // EMAIL kullan - Chat'te de email ile arayacak
                        PartyType = PartyType.Person,
                        IsBanned = false,
                        DeviceId = 0,
                        CreateDate = DateTime.UtcNow
                    };

                    await _artemisDbContext.People.AddAsync(newParty);
                    await _artemisDbContext.SaveChangesAsync();
                    partyId = newParty.Id;
                    _logger.LogInformation("Kullanıcı için Party oluşturuldu: {Email}, PartyId: {PartyId}", model.Email, partyId);
                }
                else
                {
                    partyId = existingParty.Id;
                    _logger.LogInformation("Kullanıcı için mevcut Party bulundu: {Email}, PartyId: {PartyId}", model.Email, partyId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Party oluşturulurken hata oluştu: {Email}, Error: {Error}", model.Email, ex.Message);
                // Party oluşturulamazsa bile kullanıcı kaydı başarılı sayılır
            }

            _logger.LogInformation("Yeni kullanıcı kaydedildi: {Email}", model.Email);

            return Ok(new
            {
                message = "Kayıt başarılı",
                userId = user.Id,
                email = user.Email,
                partyId = partyId
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Kayıt işlemi sırasında hata oluştu: {Email}", model.Email);
            return StatusCode(500, new { message = "Kayıt işlemi sırasında bir hata oluştu" });
        }
    }
}

