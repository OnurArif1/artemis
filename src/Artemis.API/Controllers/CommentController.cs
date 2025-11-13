using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class CommentController : ControllerBase
{
    private readonly ICommentService _commentService;

    public CommentController(ICommentService commentService)
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
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _commentService.Create(viewModel);
        }
        catch (System.Exception ex)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = $"An unknown error occurred. Exception Message: {ex.Message}";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.UnknownError;
        }

        return Ok(resultViewModel);
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateCommentViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _commentService.Update(viewModel);
        }
        catch (System.Exception ex)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = $"An unknown error occurred. Exception Message: {ex.Message}";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.UnknownError;
        }

        return Ok(resultViewModel);
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _commentService.Delete(id);
        }
        catch (System.Exception ex)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = $"An unknown error occurred. Exception Message: {ex.Message}";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.UnknownError;
        }

        return Ok(resultViewModel);
    }
}