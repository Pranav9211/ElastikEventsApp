using System.ComponentModel.DataAnnotations;

namespace event_api.Models
{
    public class QuestionModel
    {
        public string QuestionText { get; set; } = string.Empty;

        public string QuestionType { get; set; } = "text";
        // e.g., "text", "dropdown", "mcq", "image", "color"

        public List<string>? Options { get; set; } = new(); // for dropdown/mcq

        public string? ImageUrl { get; set; } // for image-based questions

        public string? DefaultValue { get; set; } // optional default answer, useful for color or text

        public bool IsRequired { get; set; } = false;
    }

    public class CustomField
    {
        [Key]
        public Guid FieldId { get; set; }

        [Required]
        public string FieldName { get; set; }

        [Required]
        public string FieldType { get; set; }

        public List<QuestionModel> Questions { get; set; } = new();

        [Required]
        public bool IsRequired { get; set; }

    }
}
