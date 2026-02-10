using Artemis.API.Entities.Enums;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json.Serialization;

namespace Artemis.API.Controllers;

public class SavePartyPurposesRequest
{
    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("purposeTypes")]
    public List<int> PurposeTypes { get; set; } = new();
}

[Route("api/[controller]")]
[ApiController]
public class PartyPurposeController : ControllerBase
{
    private readonly IPartyPurposeService _partyPurposeService;

    public PartyPurposeController(IPartyPurposeService partyPurposeService)
    {
        _partyPurposeService = partyPurposeService;
    }

    [HttpPost("save")]
    public async Task<IActionResult> SavePartyPurposesAsync([FromBody] SavePartyPurposesRequest request)
    {
        if (request == null || request.PurposeTypes == null || !request.PurposeTypes.Any())
        {
            return BadRequest(new { message = "At least one purpose must be selected." });
        }

        if (string.IsNullOrEmpty(request.Email))
        {
            return BadRequest(new { message = "Email is required." });
        }

        try
        {
            // Convert int list to enum list
            var purposeTypes = request.PurposeTypes
                .Select(pt => (PartyPurposeType)pt)
                .ToList();

            await _partyPurposeService.SavePartyPurposesAsync(request.Email, purposeTypes);
            return Ok(new { message = "Your purposes have been saved successfully." });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "An error occurred: " + ex.Message });
        }
    }
}
