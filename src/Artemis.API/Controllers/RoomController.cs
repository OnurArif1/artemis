using Artemis.API.Entities;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class RoomController : ControllerBase
{
    private readonly IRoomService _roomService;

    public RoomController(IRoomService roomService)
    {
        _roomService = roomService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] RoomFilterViewModel viewModel)
    {
        var viewModels = await _roomService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateRoomViewModel viewModel)
    {
        await _roomService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateRoomViewModel viewModel)
    {
        await _roomService.Update(viewModel);
        return Ok();
    }
    [HttpPost("delete")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _roomService.Delete(id);
        return Ok();
    }
}