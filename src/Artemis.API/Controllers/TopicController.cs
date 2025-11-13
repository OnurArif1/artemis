using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class TopicController : ControllerBase
{
    private readonly ITopicService _topicService;

    public PartyController(ITopicService topicService)
    {
        _topicService = topicService;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetByIdAsync(int id)
    {
        var viewModel = await _topicService.GetById(id);
        if (viewModel == null)
        {
            return NotFound();
        }
        
        return Ok(viewModel);
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] TopicFilterViewModel viewModel)
    {
        var viewModels = await _topicService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateTopicViewModel viewModel)
    {
        await _topicService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateTopicViewModel viewModel)
    {
        await _topicService.Update(viewModel);
        return Ok();
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _topicService.Delete(id);
        return Ok();
    }
}