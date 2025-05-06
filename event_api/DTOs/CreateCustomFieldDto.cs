namespace event_api.DTOs
{
    public class CreateCustomFieldDto
    {
        public string FieldName { get; set; }
        public string FieldType { get; set; }
        public List<QuestionDto> Questions { get; set; }
        public bool IsRequired { get; set; }
    }

}
