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

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupPartyViewModel viewmodel)
    {
        var parties = await _partyService.GetPartyLookup(viewmodel);
        return Ok(parties);
    }
}