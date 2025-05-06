namespace event_api.DTOs
{
    public class QuestionDto
    {
        public string QuestionText { get; set; }
        public string QuestionType { get; set; }
        public List<string>? Options { get; set; }
        public string? ImageUrl { get; set; }
        public string? DefaultValue { get; set; }
        public bool IsRequired { get; set; }
    }

}
