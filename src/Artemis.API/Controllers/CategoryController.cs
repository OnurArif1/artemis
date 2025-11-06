using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;


namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class CategoryController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CategoryController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] CategoryFilterViewModel viewModel)
    {
        var viewModels = await _categoryService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupCategoryViewModel viewmodel)
    {
        var categories = await _categoryService.GetCategoryLookup(viewmodel);
        return Ok(categories);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateCategoryViewModel viewModel)
    {
        await _categoryService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateCategoryViewModel viewModel)
    {
        await _categoryService.Update(viewModel);
        return Ok();
    }
    
    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _categoryService.Delete(id);
        return Ok();
    }
}