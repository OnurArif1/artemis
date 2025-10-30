using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreatePartyViewModel
{
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}