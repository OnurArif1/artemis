using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum TopicLookupSearchType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "Title")]
    Title = 1,
    [Display(Name = "TopicId")]
    TopicId = 2
}

