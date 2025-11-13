using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class SubscribeController : ControllerBase
{
    private readonly ISubscribeService _subscribeService;

    public SubscribeController(ISubscribeService subscribeService)
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
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _subscribeService.Create(viewModel);
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
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateSubscribeViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _subscribeService.Update(viewModel);
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
            resultViewModel = await _subscribeService.Delete(id);
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