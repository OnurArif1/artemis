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

    [HttpGet("lookup/partyId")]
    public async Task<IActionResult> LookupPartyId([FromQuery] string partyName)
    {
        var id = await _partyService.GetPartyIdByName(partyName);
        return Ok(id);
    }

    [HttpGet("lookup/partyName")]
    public async Task<IActionResult> LookupPartyName([FromQuery] int partyId)
    {
        var name = await _partyService.GetPartyNameById(partyId);
        return Ok(name);
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupPartyViewModel viewmodel)
    {
        var parties = await _partyService.GetPartyLookup(viewmodel);
        return Ok(parties);
    }
}