using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class PersonGetViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}