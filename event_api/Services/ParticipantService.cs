using Microsoft.EntityFrameworkCore;
using event_api.DTOs;
using event_api.Services.Interfaces;
using System;
using event_api.Data;
using event_api.Models;

namespace event_api.Services
{
    public class ParticipantService : IParticipantService
    {
        private readonly ApplicationDbContext _context;

        public ParticipantService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<ParticipantDto>> GetParticipantsByEventIdAsync(Guid eventId)
        {
            var participants = await _context.Participants
                .Where(p => p.EventId == eventId)
                .Select(p => new ParticipantDto
                {
                    ParticipantId = p.ParticipantId,
                    Name = p.User.Name,
                    Email = p.User.Email,
                    EventId = p.EventId,
                    UserId=p.UserId,
                    IsAvailable = p.AvailabilityStatus == "Available",
                })
                .ToListAsync();

            return participants;
        }


        public async Task<bool> UpdateAvailabilityAsync(ParticipantAvailabilityDto dto)
        {
            var participant = await _context.Participants.FindAsync(dto.ParticipantId);
            if (participant == null)
                return false;

            participant.AvailabilityStatus = dto.IsAvailable ? "Available" : "Not Available";

            _context.Entry(participant).Property(p => p.AvailabilityStatus).IsModified = true;
            await _context.SaveChangesAsync();
            return true;
        }



        public async Task<bool> AddCommentAsync(CommentDto dto)
        {
            var comment = new Comment
            {
                EventId = dto.EventId,
                UserId = dto.UserId,
                Message = dto.Content,
                PostedAt = DateTime.UtcNow
            };

            await _context.Comments.AddAsync(comment);
            await _context.SaveChangesAsync();
            return true;
        }


        public async Task<List<CommentDto>> GetPublicCommentsAsync(Guid eventId) 
        {
            var comments = await _context.Comments
                .Where(c => c.EventId == eventId)
                .OrderByDescending(c => c.PostedAt)
                .Select(c => new CommentDto
                {
                    CommentId = c.CommentId,
                    EventId = c.EventId,
                    UserId = c.UserId,
                    Content = c.Message,
                    CreatedAt = c.PostedAt
                })
                .ToListAsync();

            return comments;
        }
    }
}
