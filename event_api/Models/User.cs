using System.ComponentModel.DataAnnotations;

namespace event_api.Models
{
    public class User
    {
        [Key]
        public Guid UserId { get; set; }

        [Required]
        public string Name { get; set; }

        [Required]
        public string Email { get; set; }

        [Required]
        public string PasswordHash { get; set; }

        [Required]
        public string Role { get; set; }  // "admin" or "participant"

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    }

}
