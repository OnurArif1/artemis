using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        public string FullName { get; set; } 

        [Required, MaxLength(200)]
        public string Email { get; set; }// username koymadım mail ile giriş yapsınlar ki kendilerini tamamen anon hissetsinler :)

        [Required]
        public string Password { get; set; }

        public bool IsPremium { get; set; } = true;

        public bool IsBanned { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<Post> Posts { get; set; }
    }
}
