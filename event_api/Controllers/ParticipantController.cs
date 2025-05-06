using Microsoft.AspNetCore.Mvc;
using event_api.DTOs;
using event_api.Services;
using event_api.Services.Interfaces;

namespace event_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ParticipantController : ControllerBase
    {
        private readonly IParticipantService _participantService;

        public ParticipantController(IParticipantService participantService)
        {
            _participantService = participantService;
        }

        [HttpGet("{eventId}/participants")]
        public async Task<IActionResult> GetParticipantsForEvent(Guid eventId)
        {
            var participants = await _participantService.GetParticipantsByEventIdAsync(eventId);
            return Ok(participants);
        }

        [HttpPost("update-availability")]
        public async Task<IActionResult> UpdateAvailability([FromBody] ParticipantAvailabilityDto dto)
        {
            var result = await _participantService.UpdateAvailabilityAsync(dto);
            if (!result)
                return NotFound(new { message = "Participant not found." });

            return Ok(new { message = "Availability updated successfully." });
        }


        [HttpPost("add-comment")]
        public async Task<IActionResult> AddComment([FromBody] CommentDto dto)
        {
            var success = await _participantService.AddCommentAsync(dto);
            if (!success)
                return BadRequest("Comment not added.");
            return Ok("Comment added successfully.");
        }

        [HttpGet("{eventId}/comments")]
        public async Task<IActionResult> GetPublicComments(Guid eventId)
        {
            var comments = await _participantService.GetPublicCommentsAsync(eventId);
            return Ok(comments);
        }
    }
}
