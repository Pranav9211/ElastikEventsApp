using event_api.DTOs;
using event_api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace event_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]

    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;

        public AuthController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var response = await _userService.LoginAsync(request);
            return Ok(response); // includes Token, Role, RedirectUrl
        }

    }
}
