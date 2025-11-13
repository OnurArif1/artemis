using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class RoomHashtagMapController : ControllerBase
{
    private readonly IRoomHashtagMapService _roomHashtagMapService;

    public RoomHashtagMapController(IRoomHashtagMapService roomHashtagMapService)
    {
        _roomHashtagMapService = roomHashtagMapService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] RoomHashtagMapFilterViewModel viewModel)
    {
        var viewModels = await _roomHashtagMapService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateRoomHashtagMapViewModel viewModel)
    {
        await _roomHashtagMapService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateRoomHashtagMapViewModel viewModel)
    {
        await _roomHashtagMapService.Update(viewModel);
        return Ok();
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupRoomHashtagMapViewModel viewModel)
    {
        var maps = await _roomHashtagMapService.GetLookup(viewModel);
        return Ok(maps);
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _roomHashtagMapService.Delete(id);
        return Ok();
    }
}
