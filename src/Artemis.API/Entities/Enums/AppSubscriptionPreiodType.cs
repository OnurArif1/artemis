using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum AppSubscriptionPeriodType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "Monthly")]
    Monthly = 1,
    [Display(Name = "Yearly")]
    Yearly = 2
}