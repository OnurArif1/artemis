using System.ComponentModel.DataAnnotations;

namespace Artemis.API.Entities.Enums;

public enum RoomType
{
    [Display(Name = "None")]
    None = 0,
    [Display(Name = "Public")]
    Public = 1,
    [Display(Name = "Private")]
    Private = 2
}