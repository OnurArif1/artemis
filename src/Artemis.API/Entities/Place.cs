using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace src.Artemis.API.Entities
{
    public class Place
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(150)]
        public string Name { get; set; }

        [MaxLength(250)]
        public string? Description { get; set; }

        [Required]
        public int PlaceCategoryId { get; set; }
        public PlaceCategory PlaceCategory { get; set; }
        public ICollection<Topic> Topics { get; set; }
    }
}
