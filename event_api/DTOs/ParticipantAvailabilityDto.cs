namespace event_api.DTOs
{
    public class ParticipantAvailabilityDto
    {
        public Guid ParticipantId { get; set; }
        public bool IsAvailable { get; set; }
    }
}
