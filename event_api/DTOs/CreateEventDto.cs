namespace event_api.DTOs
{
    public class CreateEventDto
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string Location { get; set; }
        public List<Guid> CustomFieldIds { get; set; }
    }
}
