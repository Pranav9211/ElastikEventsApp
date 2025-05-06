using event_api.DTOs;

namespace event_api.Services.Interfaces
{
    public interface IParticipantService
    {
        Task<List<ParticipantDto>> GetParticipantsByEventIdAsync(Guid eventId);
        Task<bool> UpdateAvailabilityAsync(ParticipantAvailabilityDto dto);
        Task<bool> AddCommentAsync(CommentDto dto);
        Task<List<CommentDto>> GetPublicCommentsAsync(Guid eventId);
    }
}
