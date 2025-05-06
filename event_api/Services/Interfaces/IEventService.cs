using event_api.Models;

namespace event_api.Services.Interfaces

{
    public interface IEventService
    {
        Task<List<Event>> GetAllEventsAsync();
        Task<Event> GetEventByIdAsync(Guid eventId);

    }

}
