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
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _topicService.Create(viewModel);
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
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateTopicViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _topicService.Update(viewModel);
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
            resultViewModel = await _topicService.Delete(id);
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