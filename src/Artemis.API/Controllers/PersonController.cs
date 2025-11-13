using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class PersonController : ControllerBase
{
    private readonly IPersonService _personService;

    public PersonController(IPersonService personService)
    {
        _personService = personService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] PersonFilterViewModel viewModel)
    {
        var viewModels = await _personService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetByIdAsync(int id)
    {
        var viewModel = await _personService.GetById(id);
        if (viewModel == null)
        {
            return NotFound();
        }
        
        return Ok(viewModel);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdatePersonViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _personService.Create(viewModel);
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
    public async Task<IActionResult> UpdateAsync(CreateOrUpdatePersonViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _personService.Update(viewModel);
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
            resultViewModel = await _personService.Delete(id);
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