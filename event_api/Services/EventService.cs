using event_api.Services.Interfaces;
using event_api.Data;
using Microsoft.EntityFrameworkCore;
using event_api.Models;

namespace event_api.Services
{
    public class EventService : IEventService
    {
        private readonly ApplicationDbContext _context;

        public EventService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<Event>> GetAllEventsAsync()
        {
            return await _context.Events
                .Include(e => e.EventCustomFields)
                    .ThenInclude(ecf => ecf.CustomField)
                .ToListAsync();
        }

        public async Task<Event> GetEventByIdAsync(Guid eventId)
        {
            return await _context.Events
                .Include(e => e.EventCustomFields)
                    .ThenInclude(ecf => ecf.CustomField)
                .FirstOrDefaultAsync(e => e.EventId == eventId);
        }


    }

}
