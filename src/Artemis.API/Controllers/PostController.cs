using Artemis.API.Abstract;
using Microsoft.AspNetCore.Mvc;
using src.Artemis.API.Entities;

[ApiController]
[Route("api/[controller]")]
public class PostController : ControllerBase
{
    private readonly IPost _post;
    public PostController(IPost post)
    {
        _post = post;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var values = await _post.GetAllAsync();
        return Ok(values);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var value = await _post.GetByIdAsync(id);
        if (value == null) return NotFound();
        return Ok(value);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Post dto)
    {
        await _post.AddAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] Post dto)
    {
        if (id != dto.Id) return BadRequest();
        await _post.UpdateAsync(dto);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        await _post.DeleteAsync(id);
        return NoContent();
    }
}


