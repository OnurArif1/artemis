using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum PartyLooukpSearchType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "PartyName")]
    PartyName = 1,
    [Display(Name = "PartyId")]
    PartyId = 2
}