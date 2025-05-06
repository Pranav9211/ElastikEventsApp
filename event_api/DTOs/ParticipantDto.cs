namespace event_api.DTOs
{
    public class ParticipantDto
    {
        public Guid ParticipantId { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public Guid EventId { get; set; }
        public Guid UserId { get; set; }
        public bool IsAvailable { get; set; }
    }
}
