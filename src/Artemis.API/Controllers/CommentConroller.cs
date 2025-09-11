using Artemis.API.Abstract;
using Microsoft.AspNetCore.Mvc;

public class CommentController : ControllerBase
{
    private readonly IComment _comment;
    public CommentController(IComment comment)
    {
        _comment = comment;
    }

    [HttpGet]
    public IActionResult CommentList()
    {
        var values = _comment.GetAllAsync();
        return Ok(values);
    }
}