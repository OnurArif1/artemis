using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class MentionController : ControllerBase
{
    private readonly IMentionService _mentionService;

    public MentionController(IMentionService mentionService)
    {
        _mentionService = mentionService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] MentionFilterViewModel viewModel)
    {
        var viewModels = await _mentionService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateMentionViewModel viewModel)
    {
        try
        {
            await _mentionService.Create(viewModel);
            return Ok();
        }
        catch (DbUpdateException ex)
        {
            var innerMessage = ex.InnerException?.Message ?? ex.Message;
            return BadRequest(new { message = $"Database error: {innerMessage}" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateMentionViewModel viewModel)
    {
        try
        {
            await _mentionService.Update(viewModel);
            return Ok();
        }
        catch (DbUpdateException ex)
        {
            var innerMessage = ex.InnerException?.Message ?? ex.Message;
            return BadRequest(new { message = $"Database error: {innerMessage}" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupMentionViewModel viewModel)
    {
        var mentions = await _mentionService.GetLookup(viewModel);
        return Ok(mentions);
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _mentionService.Delete(id);
        return Ok();
    }
}

