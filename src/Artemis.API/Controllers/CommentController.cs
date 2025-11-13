using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class CommentController : ControllerBase
{
    private readonly ICommentService _commentService;

    public PartyController(ITopicService commentService)
    {
        _commentService = commentService;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetByIdAsync(int id)
    {
        var viewModel = await _commentService.GetById(id);
        if (viewModel == null)
        {
            return NotFound();
        }
        
        return Ok(viewModel);
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] CommentFilterViewModel viewModel)
    {
        var viewModels = await _commentService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateCommentViewModel viewModel)
    {
        await _commentService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateCommentViewModel viewModel)
    {
        await _commentService.Update(viewModel);
        return Ok();
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _commentService.Delete(id);
        return Ok();
    }
}