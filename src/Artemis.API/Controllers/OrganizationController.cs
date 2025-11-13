using Artemis.API.Entities;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class OrganizationController : ControllerBase
{
    private readonly IOrganizationService _organizationService;

    public OrganizationController(IOrganizationService organizationService)
    {
        _organizationService = organizationService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] OrganizationFilterViewModel viewModel)
    {
        var viewModels = await _organizationService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetByIdAsync(int id)
    {
        var viewModel = await _organizationService.GetById(id);
        if (viewModel == null)
        {
            return NotFound();
        }
        
        return Ok(viewModel);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateOrganizationViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _organizationService.Create(viewModel);
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
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateOrganizationViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _organizationService.Update(viewModel);
        }
        catch (System.Exception ex)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = $"An unknown error occurred. Exception Message: {ex.Message}";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.UnknownError;
        }

        return Ok(resultViewModel);
    }

    [HttpPost("delete")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        try
        {
            resultViewModel = await _organizationService.Delete(id);
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