using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Services;

[Route("api/[controller]")]
[ApiController]
public class PersonController : ControllerBase
{
    private readonly IPersonService _personService;

    public PartyController(IPersonService personService)
    {
        _personService = personService;
    }

    [HttpGet("list")]
    public async Task<IActionResult> GetListAsync([FromQuery] PersonFilterViewModel viewModel)
    {
        var viewModels = await _personService.GetList(viewModel);
        return Ok(viewModels);
    }

    [HttpPost("create")]
    public async Task<IActionResult> CreateAsync(CreateOrUpdatePersonViewModel viewModel)
    {
        await _personService.Create(viewModel);
        return Ok();
    }

    [HttpPost("update")]
    public async Task<IActionResult> UpdateAsync(CreateOrUpdatePersonViewModel viewModel)
    {
        await _personService.Update(viewModel);
        return Ok();
    }

    [HttpDelete("delete/{id}")]
    public async Task<IActionResult> DeleteAsync(int id)
    {
        await _personService.Delete(id);
        return Ok();
    }
}