using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum SubscriptionType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "Silver")]
    Silver = 1,
    [Display(Name = "Gold")]
    Gold = 2,
    [Display(Name = "Platinum")]
    Platinum = 3
}