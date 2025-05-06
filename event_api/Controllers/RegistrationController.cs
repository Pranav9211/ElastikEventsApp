using event_api.DTOs;
using event_api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace event_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RegistrationController : ControllerBase
    {
        private readonly IRegistrationService _RegistrationFieldservice;

        public RegistrationController(IRegistrationService RegistrationFieldservice)
        {
            _RegistrationFieldservice = RegistrationFieldservice;
        }

        [HttpGet("{userId}/{eventCustomFieldId}")]
        public async Task<IActionResult> GetRegistrationFields(Guid userId, Guid eventCustomFieldId)
        {
            var fields = await _RegistrationFieldservice.GetRegistrationFieldsByUserAndEventAsync(userId, eventCustomFieldId);
            return Ok(fields);
        }

        [HttpPost]
public async Task<IActionResult> CreateRegistration([FromBody] RegistrationCreateDto dto)
{
    var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
    var result = await _RegistrationFieldservice.CreateRegistrationAsync(dto, userId);
    return Ok(result);
}
    }
    }
