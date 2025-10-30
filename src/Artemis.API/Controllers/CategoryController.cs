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

    [HttpGet("lookup/categoryId")]
    public async Task<IActionResult> LookupCategoryId([FromQuery] string categoryName)
    {
        var id = await _categoryService.GetCategoryIdByName(categoryName);
        return Ok(id);
    }

    [HttpGet("lookup/categoryName")]
    public async Task<IActionResult> LookupCategoryName([FromQuery] int categoryId)
    {
        var name = await _categoryService.GetCategoryNameById(categoryId);
        return Ok(name);
    }
}