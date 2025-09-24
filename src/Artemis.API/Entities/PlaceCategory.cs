using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class PlaceCategory
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; } 

        [MaxLength(250)]
        public string? Description { get; set; }

        public ICollection<Place> Places { get; set; }
    }
}
