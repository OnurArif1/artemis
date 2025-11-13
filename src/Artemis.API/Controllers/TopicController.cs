using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class TopicController : ControllerBase
{
    private readonly ITopicService _topicService;

    public TopicController(ITopicService topicService)
    {
        _topicService = topicService;
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupTopicViewModel viewModel)
    {
        var topics = await _topicService.GetTopicLookup(viewModel);
        return Ok(topics);
    }
}

