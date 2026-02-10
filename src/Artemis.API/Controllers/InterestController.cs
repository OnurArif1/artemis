using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class InterestController : ControllerBase
{
    private readonly IInterestService _interestService;

    public InterestController(IInterestService interestService)
    {
        _interestService = interestService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync()
    {
        var interests = await _interestService.GetListAsync();
        return Ok(interests);
    }
}
