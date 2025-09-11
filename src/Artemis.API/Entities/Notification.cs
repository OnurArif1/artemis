using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class Notification
    {
        public int Id { get; set; }

        [Required, MaxLength(200)]
        public string Message { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? UserId { get; set; }
        public User? User { get; set; }

        public bool IsRead { get; set; } = false;
    }

}
