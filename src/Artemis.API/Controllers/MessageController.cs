using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class MessageController : ControllerBase
{
    private readonly IMessageService _messageService;

    public MessageController(IMessageService messageService)
    {
        _messageService = messageService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] MessageFilterViewModel viewModel)
    {
        var viewModels = await _messageService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateMessageViewModel viewModel)
    {
        try
        {
            await _messageService.Create(viewModel);
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
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateMessageViewModel viewModel)
    {
        try
        {
            await _messageService.Update(viewModel);
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

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        try
        {
            await _messageService.Delete(id);
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
}

