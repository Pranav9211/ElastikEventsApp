using event_api.DTOs;

namespace event_api.Services.Interfaces
{
    public interface IRegistrationService
    {
        Task<List<RegistrationDto>> GetRegistrationFieldsByUserAndEventAsync(Guid userId, Guid eventId);
        Task<RegistrationDto> CreateRegistrationAsync(RegistrationCreateDto dto, Guid userId);
    }
}
