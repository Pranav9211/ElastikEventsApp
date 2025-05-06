using event_api.DTOs;
using event_api.Models;
using Event = event_api.Models.Event;

namespace event_api.Services.Interfaces
{
    public interface IAdminService
    {
        Task<(bool isSuccess, string message, Guid? eventId)> CreateEventAsync(CreateEventDto dto, Guid adminId);
        Task<(bool isSuccess, string message, Guid? fieldId)> CreateCustomFieldAsync(CreateCustomFieldDto dto);
        Task<(bool isSuccess, string message)> AssignFieldsToEventAsync(AddFieldToEventDto dto);
        Task<List<CustomField>> GetAllCustomFieldsAsync();
        Task<List<Event>> GetAllEventsAsync();
        Task<(bool isSuccess, string message)> DeleteEventAsync(Guid eventId);
    }
}
