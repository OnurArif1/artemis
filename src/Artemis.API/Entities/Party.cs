using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class Party : BaseEntity
{
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
}