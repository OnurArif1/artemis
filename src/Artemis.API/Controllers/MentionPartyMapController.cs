using Artemis.API.Entities;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class MentionPartyMapController : ControllerBase
{
    private readonly IMentionPartyMapService _mentionPartyMapService;

    public RoomController(IMentionPartyMapService mentionPartyMapService)
    {
        _mentionPartyMapService = mentionPartyMapService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] MentionPartyMapFilterViewModel viewModel)
    {
        var viewModels = await _mentionPartyMapService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        await _roomService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        await _mentionPartyMapService.Update(viewModel);
        return Ok();
    }
    [HttpPost("delete")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _mentionPartyMapService.Delete(id);
        return Ok();
    }
}