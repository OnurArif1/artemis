using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class TopicHashtagMapController : ControllerBase
{
    private readonly ITopicHashtagMapService _topicHashtagMapService;

    public TopicHashtagMapController(ITopicHashtagMapService topicHashtagMapService)
    {
        _topicHashtagMapService = topicHashtagMapService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] TopicHashtagMapFilterViewModel viewModel)
    {
        var viewModels = await _topicHashtagMapService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateTopicHashtagMapViewModel viewModel)
    {
        await _topicHashtagMapService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateTopicHashtagMapViewModel viewModel)
    {
        await _topicHashtagMapService.Update(viewModel);
        return Ok();
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupTopicHashtagMapViewModel viewModel)
    {
        var maps = await _topicHashtagMapService.GetLookup(viewModel);
        return Ok(maps);
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _topicHashtagMapService.Delete(id);
        return Ok();
    }
}

