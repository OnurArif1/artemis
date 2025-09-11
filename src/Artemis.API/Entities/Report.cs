using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class Report
    {
        public int Id { get; set; }

        [Required, MaxLength(250)]
        public string Reason { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int PostId { get; set; }
        public Post Post { get; set; }

        public int UserId { get; set; }
        public User User { get; set; }

        public bool IsResolved { get; set; } = false;
    }
}
