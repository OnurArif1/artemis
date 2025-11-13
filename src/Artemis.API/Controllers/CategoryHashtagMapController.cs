using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class CategoryHashtagMapController : ControllerBase
{
    private readonly ICategoryHashtagMapService _categoryHashtagMapService;

    public CategoryHashtagMapController(ICategoryHashtagMapService categoryHashtagMapService)
    {
        _categoryHashtagMapService = categoryHashtagMapService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] CategoryHashtagMapFilterViewModel viewModel)
    {
        var viewModels = await _categoryHashtagMapService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateCategoryHashtagMapViewModel viewModel)
    {
        await _categoryHashtagMapService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateCategoryHashtagMapViewModel viewModel)
    {
        await _categoryHashtagMapService.Update(viewModel);
        return Ok();
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupCategoryHashtagMapViewModel viewModel)
    {
        var maps = await _categoryHashtagMapService.GetLookup(viewModel);
        return Ok(maps);
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _categoryHashtagMapService.Delete(id);
        return Ok();
    }
}

