using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class AppSubscriptionTypePricesController : ControllerBase
{
    private readonly IAppSubscriptionTypePricesService _appSubscriptionTypePricesService;

    public AppSubscriptionTypePricesController(IAppSubscriptionTypePricesService appSubscriptionTypePricesService)
    {
        _appSubscriptionTypePricesService = appSubscriptionTypePricesService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] AppSubscriptionTypePricesFilterViewModel viewModel)
    {
        var viewModels = await _appSubscriptionTypePricesService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel)
    {
        await _appSubscriptionTypePricesService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel)
    {
        await _appSubscriptionTypePricesService.Update(viewModel);
        return Ok();
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _appSubscriptionTypePricesService.Delete(id);
        return Ok();
    }
}
