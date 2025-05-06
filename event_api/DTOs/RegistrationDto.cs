using event_api.Models;
using System.ComponentModel.DataAnnotations;

namespace event_api.DTOs
{
    public class RegistrationCreateDto
    {
        [Required]
        public Guid EventCustomFieldId { get; set; }

        [Required]
        public List<AnswerDto> Answers { get; set; } = new();
    }

    public class RegistrationDto
    {
        public Guid RegistrationFieldId { get; set; }
        public Guid EventCustomFieldId { get; set; }
        public Guid EventId { get; set; }
        public string FieldName { get; set; }
        public string FieldType { get; set; }
        public List<AnswerDto> Answers { get; set; } = new();
    }

}
