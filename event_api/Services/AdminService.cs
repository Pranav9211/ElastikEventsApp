using event_api.DTOs;
using event_api.Services.Interfaces;
using event_api.Data;
using event_api.Models;
using Microsoft.EntityFrameworkCore;

namespace event_api.Services
{
    public class AdminService : IAdminService
    {
        private readonly ApplicationDbContext _context;

        public AdminService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<(bool isSuccess, string message, Guid? eventId)> CreateEventAsync(CreateEventDto dto, Guid adminId)
        {
            if (dto == null) return (false, "Event data is required.", null);

            var newEvent = new Event
            {
                EventId = Guid.NewGuid(),
                Title = dto.Title,
                Description = dto.Description,
                Location = dto.Location,
                CreateBy = adminId,
                CreatedAt = DateTime.UtcNow
            };

            await _context.Events.AddAsync(newEvent);

            if (dto.CustomFieldIds != null && dto.CustomFieldIds.Any())
            {
                var validFieldIds = await _context.CustomFields
                    .Where(f => dto.CustomFieldIds.Contains(f.FieldId))
                    .Select(f => f.FieldId)
                    .ToListAsync();

                var invalidFieldIds = dto.CustomFieldIds.Except(validFieldIds).ToList();

                if (invalidFieldIds.Any())
                {
                    return (false, $"Invalid CustomField IDs: {string.Join(", ", invalidFieldIds)}", null);
                }

                var eventCustomFields = validFieldIds.Select(fieldId => new EventCustomField
                {
                    EventCustomFieldId = Guid.NewGuid(),
                    EventId = newEvent.EventId,
                    CustomFieldFieldId = fieldId
                }).ToList();

                await _context.EventCustomFields.AddRangeAsync(eventCustomFields);

                //var RegistrationFields = eventCustomFields.Select(ecf => new Registration
                //{
                //    RegistrationFieldId = Guid.NewGuid(),
                //    EventCustomFieldId = ecf.EventCustomFieldId,
                //    UserId = adminId,
                //    Value = "Default"
                //}).ToList();

                //await _context.RegistrationFields.AddRangeAsync(RegistrationFields);
            }

            // ✅ Add all participants with 'tentative' availability
            var participantUsers = await _context.Users
                .Where(u => u.Role == "participant")
                .ToListAsync();

            var participants = participantUsers.Select(user => new Participant
            {
                ParticipantId = Guid.NewGuid(),
                EventId = newEvent.EventId,
                UserId = user.UserId,
                AvailabilityStatus = "tentative"
            }).ToList();

            await _context.Participants.AddRangeAsync(participants);

            await _context.SaveChangesAsync();

            return (true, "Event created successfully.", newEvent.EventId);
        }
        public async Task<(bool isSuccess, string message, Guid? fieldId)> CreateCustomFieldAsync(CreateCustomFieldDto dto)
        {
            if (dto == null) return (false, "Custom field data is required.", null);

            if (dto.Questions == null || !dto.Questions.Any())
                return (false, "At least one question is required.", null);

            // Map DTO Questions to Model Questions
            var questions = dto.Questions.Select(q => new QuestionModel
            {
                QuestionText = q.QuestionText,
                QuestionType = q.QuestionType,
                Options = q.Options ?? new List<string>(), // Optional, default to empty list if null
                ImageUrl = q.ImageUrl,
                DefaultValue = q.DefaultValue,
                IsRequired = q.IsRequired
            }).ToList();

            var field = new CustomField
            {
                FieldId = Guid.NewGuid(),
                FieldName = dto.FieldName,
                FieldType = dto.FieldType,
                Questions = questions, // Use mapped Questions
                IsRequired = dto.IsRequired
            };

            await _context.CustomFields.AddAsync(field);
            await _context.SaveChangesAsync();

            return (true, "Custom field created successfully.", field.FieldId);
        }

        public async Task<(bool isSuccess, string message)> AssignFieldsToEventAsync(AddFieldToEventDto dto)
        {
            if (dto == null) return (false, "Assignment data is required.");

            var eventExists = await _context.Events.AnyAsync(e => e.EventId == dto.EventId);
            if (!eventExists) return (false, $"Event with ID {dto.EventId} not found.");

            var validFieldIds = await _context.CustomFields
                .Where(f => dto.FieldIds.Contains(f.FieldId))
                .Select(f => f.FieldId)
                .ToListAsync();

            var invalidFieldIds = dto.FieldIds.Except(validFieldIds).ToList();

            if (invalidFieldIds.Any())
            {
                return (false, $"Invalid Field IDs: {string.Join(", ", invalidFieldIds)}");
            }

            var assignments = validFieldIds.Select(fieldId => new EventCustomField
            {
                EventCustomFieldId = Guid.NewGuid(),  // Use more descriptive ID
                EventId = dto.EventId,
                CustomFieldFieldId = fieldId
            }).ToList();

            await _context.EventCustomFields.AddRangeAsync(assignments);
            await _context.SaveChangesAsync();

            // Optionally, create default registration fields
            var RegistrationFields = assignments.Select(ecf => new Registration
            {
                RegistrationFieldId = Guid.NewGuid(),
                EventCustomFieldId = ecf.EventCustomFieldId,
                UserId = dto.AdminId, // Admin or default user
                Value = "Default"  // Default or placeholder value
            }).ToList();

            await _context.RegistrationFields.AddRangeAsync(RegistrationFields);
            await _context.SaveChangesAsync();

            return (true, "Fields assigned successfully.");
        }

        public async Task<List<CustomField>> GetAllCustomFieldsAsync()
        {
            return await _context.CustomFields.ToListAsync();
        }

        public async Task<List<Event>> GetAllEventsAsync()
        {
            return await _context.Events
                .Include(e => e.EventCustomFields)
                    .ThenInclude(ecf => ecf.CustomField)
                .ToListAsync();
        }

        public async Task<(bool isSuccess, string message)> DeleteEventAsync(Guid eventId)
        {
            var existingEvent = await _context.Events
                .Include(e => e.EventCustomFields)
                .FirstOrDefaultAsync(e => e.EventId == eventId);

            if (existingEvent == null)
            {
                return (false, $"Event with ID {eventId} not found.");
            }

            // Delete participants that reference this event
            var participants = await _context.Participants
                .Where(p => p.EventId == eventId)
                .ToListAsync();

            _context.Participants.RemoveRange(participants);

            // Delete associated EventCustomFields and RegistrationFields
            _context.EventCustomFields.RemoveRange(existingEvent.EventCustomFields);

            var RegistrationFields = await _context.RegistrationFields
                .Where(rf => existingEvent.EventCustomFields
                    .Select(ecf => ecf.EventCustomFieldId)
                    .Contains(rf.EventCustomFieldId))
                .ToListAsync();

            _context.RegistrationFields.RemoveRange(RegistrationFields);

            _context.Events.Remove(existingEvent);

            await _context.SaveChangesAsync();

            return (true, "Event deleted successfully.");
        }
    }
}
