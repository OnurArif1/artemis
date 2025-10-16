using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Artemis.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Tüm controller authorize
public class TestController : ControllerBase
{
    [HttpGet("public")]    public IActionResult GetPublic()
    {
        return Ok(new 
        { 
            message = "Bu endpoint herkese açık (Gateway test için)", 
            timestamp = DateTime.UtcNow 
        });
    }

    [HttpGet("protected")]
    public IActionResult GetProtected()
    {
        // authorize ol ve buraya düş
        var user = User.Identity?.Name;
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        
        return Ok(new 
        { 
            message = "Bu endpoint korumalı", 
            user = user,
            claims = claims,
            timestamp = DateTime.UtcNow 
        });
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public IActionResult GetAdmin()
    {
        var user = User.Identity?.Name;
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        
        return Ok(new 
        { 
            message = "Bu endpoint sadece admin'ler için", 
            user = user,
            claims = claims,
            timestamp = DateTime.UtcNow 
        });
    }

    [HttpGet("user")]
    [Authorize(Roles = "User")]
    public IActionResult GetUser()
    {
        var user = User.Identity?.Name;
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        
        return Ok(new 
        { 
            message = "Bu endpoint sadece user'lar için", 
            user = user,
            claims = claims,
            timestamp = DateTime.UtcNow 
        });
    }
}
