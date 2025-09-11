using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class Post
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(500)]
        public string Content { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public int TopicId { get; set; }
        public Topic Topic { get; set; }

         [Required]
        public int UserId { get; set; }
        public User User { get; set; }
        public ICollection<Comment> Comments { get; set; }
    }
}
