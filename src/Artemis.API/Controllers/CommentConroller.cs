using Artemis.API.Abstract;
using Microsoft.AspNetCore.Mvc;
using src.Artemis.API.Entities;

[ApiController]
[Route("api/[controller]")]
public class CommentController : ControllerBase
{
    private readonly IComment _comment;
    public CommentController(IComment comment)
    {
        _comment = comment;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var values = await _comment.GetAllAsync();
        return Ok(values);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var value = await _comment.GetByIdAsync(id);
        if (value == null) return NotFound();
        return Ok(value);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Comment dto)
    {
        await _comment.AddAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] Comment dto)
    {
        if (id != dto.Id) return BadRequest();
        await _comment.UpdateAsync(dto);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        await _comment.DeleteAsync(id);
        return NoContent();
    }
}