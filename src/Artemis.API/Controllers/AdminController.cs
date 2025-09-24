using Artemis.API.Abstract;
using Microsoft.AspNetCore.Mvc;
using src.Artemis.API.Entities;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly IAdmin _admin;
    public AdminController(IAdmin admin)
    {
        _admin = admin;
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("me")]
    public IActionResult Me()
    {
        return Ok(new { email = User.Identity?.Name, claims = User.Claims.Select(c => new { c.Type, c.Value }) });
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] Admin dto)
    {
        await _admin.AddAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var admin = await _admin.GetByIdAsync(id);
        if (admin == null) return NotFound();
        return Ok(admin);
    }
}


