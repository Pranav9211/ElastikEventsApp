namespace event_api.DTOs
{
    public class AnswerDto
    {
        public string QuestionText { get; set; }
        public string? QuestionType { get; set; }
        public string Value { get; set; } // The user's answer
        public List<string>? Options { get; set; } // Available options (for reference)
        public bool? IsRequired { get; set; }
    }
}
