namespace event_api.DTOs
{
    public class CommentDto
    {
        public Guid CommentId { get; set; }
        public Guid EventId { get; set; }
        public Guid UserId { get; set; }
        public string Content { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
