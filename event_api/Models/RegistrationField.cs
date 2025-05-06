using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace event_api.Models
{
    public class Registration
    {
        [Key]
        public Guid RegistrationFieldId { get; set; }

        [Required]
        public Guid EventCustomFieldId { get; set; }

        [ForeignKey("EventCustomFieldId")]
        public EventCustomField EventCustomField { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; }

        [Required]
        public string Value { get; set; }
    }
}
