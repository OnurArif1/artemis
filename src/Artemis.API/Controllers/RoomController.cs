using Artemis.API.Entities;
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
    public async Task<IActionResult> CreateAsync(Room room)
    {
        await _roomService.Create(room);
        return Ok();
    }
}