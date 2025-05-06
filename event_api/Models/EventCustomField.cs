using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace event_api.Models
{
    public class EventCustomField
    {
        [Key]
        public Guid EventCustomFieldId { get; set; }

        [Required]
        public Guid EventId { get; set; }

        [ForeignKey("EventId")]
        [JsonIgnore]
        public Event Event { get; set; }

        [Required]
        public Guid CustomFieldFieldId { get; set; }

        [ForeignKey("CustomFieldFieldId")]
        public CustomField CustomField { get; set; }
    }
}
