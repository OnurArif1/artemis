using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text.Json.Serialization;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class PartyController : ControllerBase
{
    private readonly IPartyService _partyService;

    public PartyController(IPartyService partyService)
    {
        _partyService = partyService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] PartyFilterViewModel viewModel)
    {
        var viewModels = await _partyService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdatePartyViewModel viewModel)
    {
        await _partyService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdatePartyViewModel viewModel)
    {
        await _partyService.Update(viewModel);
        return Ok();
    }

    [HttpPost("update-profile")]
    public async Task<IActionResult> UpdateProfileAsync([FromBody] UpdatePartyProfileRequest request)
    {
        if (request == null || string.IsNullOrEmpty(request.PartyName))
        {
            return BadRequest(new { message = "Party name is required." });
        }

        // Get user's email from JWT token
        var email = User.FindFirstValue(ClaimTypes.Email) ?? User.FindFirstValue("email");
        if (string.IsNullOrEmpty(email))
        {
            return Unauthorized(new { message = "User information not found." });
        }

        try
        {
            await _partyService.UpdateByEmail(email, request.PartyName, request.Description);
            return Ok(new { message = "Profile updated successfully." });
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

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupPartyViewModel viewmodel)
    {
        var parties = await _partyService.GetPartyLookup(viewmodel);
        return Ok(parties);
    }
    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _partyService.Delete(id);
        return Ok();
    }
}

public class UpdatePartyProfileRequest
{
    [JsonPropertyName("partyName")]
    public string PartyName { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }
}