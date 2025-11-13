using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class SubscribeController : ControllerBase
{
    private readonly ISubscribeService _subscribeService;

    public PartyController(ISubscribeService subscribeService)
    {
        _subscribeService = subscribeService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] SubscribeFilterViewModel viewModel)
    {
        var viewModels = await _subscribeService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateSubscribeViewModel viewModel)
    {
        await _subscribeService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateSubscribeViewModel viewModel)
    {
        await _subscribeService.Update(viewModel);
        return Ok();
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _subscribeService.Delete(id);
        return Ok();
    }
}