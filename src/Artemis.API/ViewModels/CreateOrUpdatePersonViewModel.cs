using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreateOrUpdatePersonViewModel
{
    public int? Id { get; set; } = null;
    public string PartyName { get; set; } = string.Empty;
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}