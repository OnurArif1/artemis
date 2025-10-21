using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum PartyType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "Person")]
    Person = 1,
    [Display(Name = "Organization")]
    Organization = 2
}