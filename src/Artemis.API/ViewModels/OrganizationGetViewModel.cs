using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class OrganizationGetViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; } = string.Empty;
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}