using Artemis.API.Entities;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class OrganizationController : ControllerBase
{
    private readonly IOrganizationService _organizationService;

    public RoomController(IOrganizationService organizationService)
    {
        _organizationService = organizationService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] OrganizationFilterViewModel viewModel)
    {
        var viewModels = await _organizationService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateOrganizationViewModel viewModel)
    {
        await _organizationService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateOrganizationViewModel viewModel)
    {
        await _organizationService.Update(viewModel);
        return Ok();
    }
    [HttpPost("delete")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _organizationService.Delete(id);
        return Ok();
    }
}