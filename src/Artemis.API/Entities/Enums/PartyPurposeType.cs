using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum PartyPurposeType
{
    [Display(Name = "NotSet")]
    NotSet = 0,
    [Display(Name = "Socializing")]
    Socializing = 1,
    [Display(Name = "Dating")]
    Dating = 2,
    [Display(Name = "Networking")]
    Networking = 3,
    [Display(Name = "Making Friends")]
    MakingFriends = 4,
    [Display(Name = "Exploring")]
    Exploring = 5
}
