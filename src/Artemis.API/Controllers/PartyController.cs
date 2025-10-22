using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


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
}