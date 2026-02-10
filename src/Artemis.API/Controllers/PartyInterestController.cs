using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text.Json.Serialization;

namespace Artemis.API.Services;

public class SavePartyInterestsRequest
{
    [JsonPropertyName("interestIds")]
    public List<int> InterestIds { get; set; } = new();
}

[Route("api/[controller]")]
[ApiController]
public class PartyInterestController : ControllerBase
{
    private readonly IPartyInterestService _partyInterestService;

    public PartyInterestController(IPartyInterestService partyInterestService)
    {
        _partyInterestService = partyInterestService;
    }

    [HttpPost("save")]
    public async Task<IActionResult> SavePartyInterestsAsync([FromBody] SavePartyInterestsRequest request)
    {
        if (request == null || request.InterestIds == null || !request.InterestIds.Any())
        {
            return BadRequest(new { message = "At least one interest must be selected." });
        }

        // Get user's email from JWT token
        var email = User.FindFirstValue(ClaimTypes.Email) ?? User.FindFirstValue("email");
        if (string.IsNullOrEmpty(email))
        {
            return Unauthorized(new { message = "User information not found." });
        }

        try
        {
            await _partyInterestService.SavePartyInterestsAsync(email, request.InterestIds);
            return Ok(new { message = "Your interests have been saved successfully." });
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

    [HttpGet("my-interests")]
    [Authorize]
    public async Task<IActionResult> GetMyInterestsAsync()
    {
        // Get user's email from JWT token
        var email = User.FindFirstValue(ClaimTypes.Email) ?? User.FindFirstValue("email");
        if (string.IsNullOrEmpty(email))
        {
            return Unauthorized(new { message = "User information not found." });
        }

        try
        {
            var interests = await _partyInterestService.GetMyInterestsAsync(email);
            return Ok(interests);
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
