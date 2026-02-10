using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class Party : BaseEntity, IChangingDate
{
    public string PartyName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
    public int? RoomId { get; set; }
    public ICollection<Room> Rooms { get; set; } = new List<Room>();
    
    public ICollection<MentionPartyMap> MentionPartyMaps { get; set; } = new List<MentionPartyMap>();
    public ICollection<Subscribe> CreatedSubscribes { get; set; } = new List<Subscribe>();
    public ICollection<Subscribe> SubscribedTo { get; set; } = new List<Subscribe>();
    public ICollection<PartyInterest> PartyInterests { get; set; } = new List<PartyInterest>();
}