using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UserController : ControllerBase
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IPartyService _partyService;

    public UserController(ArtemisDbContext artemisDbContext, IPartyService partyService)
    {
        _artemisDbContext = artemisDbContext;
        _partyService = partyService;
    }

    [HttpGet("profile")]
    public IActionResult GetProfile()
    {
        var userId = User.FindFirst("sub")?.Value;
        var email = User.FindFirst("email")?.Value;
        var name = User.FindFirst("name")?.Value;
        var roles = User.FindAll("role")?.Select(r => r.Value).ToList();

        return Ok(new
        {
            userId,
            email,
            name,
            roles
        });
    }

    [HttpGet("party")]
    public async Task<IActionResult> GetOrCreateParty()
    {
        try
        {
            // Tüm claim'leri logla
            var allClaims = User.Claims.Select(c => $"{c.Type}={c.Value}").ToList();
            Console.WriteLine($"[GetOrCreateParty] User Claims: {string.Join(", ", allClaims)}");

            var email = User.FindFirst("email")?.Value ?? 
                       User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            var sub = User.FindFirst("sub")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var name = User.FindFirst("name")?.Value;
            var firstName = User.FindFirst("given_name")?.Value ?? User.FindFirst("first_name")?.Value;
            var lastName = User.FindFirst("family_name")?.Value ?? User.FindFirst("last_name")?.Value;

            Console.WriteLine($"[GetOrCreateParty] Email: {email}, Sub: {sub}, Name: {name}, FirstName: {firstName}, LastName: {lastName}");

            // Email yoksa sub'ı kullan (fallback)
            string identifierToUse = email;
            if (string.IsNullOrEmpty(identifierToUse) && !string.IsNullOrEmpty(sub))
            {
                Console.WriteLine("[GetOrCreateParty] Email claim'de yok, sub kullanılıyor...");
                identifierToUse = sub;
            }

            if (string.IsNullOrEmpty(identifierToUse))
            {
                Console.WriteLine("[GetOrCreateParty] Email ve sub bulunamadı!");
                return BadRequest(new { message = "Email bulunamadı", claims = allClaims });
            }

            // Önce identifierToUse'e göre Party ara
            var existingPartyByIdentifier = await _artemisDbContext.Parties
                .FirstOrDefaultAsync(p => p.PartyName == identifierToUse && p.PartyType == PartyType.Person);

            if (existingPartyByIdentifier != null)
            {
                Console.WriteLine($"[GetOrCreateParty] ✅ Party bulundu (identifier): {existingPartyByIdentifier.Id}");
                return Ok(new
                {
                    partyId = existingPartyByIdentifier.Id,
                    partyName = existingPartyByIdentifier.PartyName
                });
            }

            // Email'e göre bulunamazsa, FirstName + LastName ile ara
            string partyName = null;
            if (!string.IsNullOrEmpty(firstName) && !string.IsNullOrEmpty(lastName))
            {
                partyName = $"{firstName} {lastName}".Trim();
            }
            else if (!string.IsNullOrEmpty(name))
            {
                partyName = name;
            }

            if (!string.IsNullOrEmpty(partyName))
            {
                var existingPartyByName = await _artemisDbContext.Parties
                    .FirstOrDefaultAsync(p => p.PartyName == partyName && p.PartyType == PartyType.Person);

                if (existingPartyByName != null)
                {
                    Console.WriteLine($"[GetOrCreateParty] ✅ Party bulundu (name): {existingPartyByName.Id}");
                    return Ok(new
                    {
                        partyId = existingPartyByName.Id,
                        partyName = existingPartyByName.PartyName
                    });
                }
            }

            // Hiçbiri bulunamazsa yeni Party oluştur (identifierToUse kullan)
            Console.WriteLine($"[GetOrCreateParty] 🔨 Yeni Party oluşturuluyor: {identifierToUse}");
            var newParty = new Person
            {
                PartyName = identifierToUse,
                PartyType = PartyType.Person,
                IsBanned = false,
                DeviceId = 0,
                CreateDate = DateTime.UtcNow
            };

            await _artemisDbContext.People.AddAsync(newParty);
            await _artemisDbContext.SaveChangesAsync();

            Console.WriteLine($"[GetOrCreateParty] ✅ Yeni Party oluşturuldu: {newParty.Id}");
            return Ok(new
            {
                partyId = newParty.Id,
                partyName = newParty.PartyName
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GetOrCreateParty] HATA: {ex.Message}");
            Console.WriteLine($"[GetOrCreateParty] StackTrace: {ex.StackTrace}");
            return StatusCode(500, new { message = $"Sunucu hatası: {ex.Message}" });
        }
    }
}

