using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class HashtagController : ControllerBase
{
    private readonly IHashtagService _hashtagService;

    public HashtagController(IHashtagService hashtagService)
    {
        _hashtagService = hashtagService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] HashtagFilterViewModel viewModel)
    {
        var viewModels = await _hashtagService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdateHashtagViewModel viewModel)
    {
        await _hashtagService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdateHashtagViewModel viewModel)
    {
        await _hashtagService.Update(viewModel);
        return Ok();
    }

    [HttpGet("lookup")]
    public async Task<IActionResult> GetLookupAsync([FromQuery] GetLookupHashtagViewModel viewmodel)
    {
        var parties = await _hashtagService.GetHashtagLookup(viewmodel);
        return Ok(parties);
    }
    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _hashtagService.Delete(id);
        return Ok();
    }
}