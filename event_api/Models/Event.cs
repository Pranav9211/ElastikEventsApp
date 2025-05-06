using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using event_api.Models;

namespace event_api.Models
{
    public class Event
    {
        [Key]
        public Guid EventId { get; set; }

        [Required]
        public string Title { get; set; }

        [Required]
        public string Description { get; set; }

        [Required]
        public string Location { get; set; }

        [Required]
        public Guid CreateBy { get; set; }  // FK to User

        [ForeignKey("CreateBy")]
        public User Creator { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<EventCustomField> EventCustomFields { get; set; }
    }
}
