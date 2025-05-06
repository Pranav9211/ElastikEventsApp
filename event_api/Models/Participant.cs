using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace event_api.Models
{
    public class Participant
    {
        [Key]
        public Guid ParticipantId { get; set; }

        [Required]
        public Guid EventId { get; set; }

        [ForeignKey("EventId")]
        public Event Event { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; }

        [Required]
        public string AvailabilityStatus { get; set; }

        public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    }
}
