using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum ExceptionType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "GreaterThanZero")]
    GreaterThanZero = 1,
    [Display(Name = "UnknownError")]
    UnknownError = 2,
    [Display(Name = "NullOrWhiteSpace")]
    NullOrWhiteSpace = 3
}