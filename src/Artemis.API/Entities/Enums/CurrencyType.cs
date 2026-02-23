using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum CurrencyType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "TL")]
    TL = 1,
    [Display(Name = "EUR")]
    EUR = 2,
    [Display(Name = "DOLLAR")]
    DOLLAR = 3
}