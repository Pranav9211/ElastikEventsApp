using System.Security.Claims;
using event_api.DTOs;
using event_api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace event_api.Controllers
{
    [ApiController]
    [Route("api/admin/events")]
    [Authorize(Roles = "admin")]
    public class AdminEventController : ControllerBase
    {
        private readonly IAdminService _adminService;

        public AdminEventController(IAdminService adminService)
        {
            _adminService = adminService;
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreateEvent([FromBody] CreateEventDto dto)
        {
            var adminId = GetCurrentUserId();
            if (adminId == Guid.Empty)
            {
                return Unauthorized("Invalid user.");
            }

            var result = await _adminService.CreateEventAsync(dto, adminId);
            if (!result.isSuccess)
                return BadRequest(result.message);

            return Ok(new { message = result.message, eventId = result.eventId });
        }

        [HttpPost("custom-field")]
        public async Task<IActionResult> CreateCustomField([FromBody] CreateCustomFieldDto dto)
        {
            var result = await _adminService.CreateCustomFieldAsync(dto);
            if (!result.isSuccess)
                return BadRequest(result.message);

            return Ok(new { message = result.message, fieldId = result.fieldId });
        }

        [HttpPost("assign-fields")]
        public async Task<IActionResult> AssignFieldsToEvent([FromBody] AddFieldToEventDto dto)
        {
            var result = await _adminService.AssignFieldsToEventAsync(dto);
            if (!result.isSuccess)
                return BadRequest(result.message);

            return Ok(new { message = result.message });
        }

        [HttpGet("custom-fields")]
        public async Task<IActionResult> GetAllCustomFields()
        {
            var fields = await _adminService.GetAllCustomFieldsAsync();
            return Ok(fields);
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAllEvents()
        {
            var events = await _adminService.GetAllEventsAsync();
            return Ok(events);
        }

        [HttpDelete("delete/{eventId}")]
        public async Task<IActionResult> DeleteEvent(Guid eventId)
        {
            var result = await _adminService.DeleteEventAsync(eventId);
            if (!result.isSuccess)
            {
                return NotFound(result.message);
            }

            return Ok(new { message = result.message });
        }


        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == "sub" || c.Type == ClaimTypes.NameIdentifier);
            if (userIdClaim == null) return Guid.Empty;

            return Guid.TryParse(userIdClaim.Value, out var userId) ? userId : Guid.Empty;
        }
    }
}
