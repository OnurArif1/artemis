using System.ComponentModel.DataAnnotations;
using Artemis.API.Entities.Enums;

namespace Identity.Api.Models;

public class RegisterRequest
{
    [Required(ErrorMessage = "E-posta gerekli.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre gerekli.")]
    [MinLength(6, ErrorMessage = "Şifre en az 6 karakter olmalı.")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$",
        ErrorMessage = "Şifre en az bir büyük harf, bir küçük harf ve bir rakam içermelidir.")]
    public string Password { get; set; } = string.Empty;

    public string? PartyName { get; set; }

    public PartyType PartyType { get; set; }

    public int? DeviceId { get; set; }

    public bool? IsBanned { get; set; }
}
