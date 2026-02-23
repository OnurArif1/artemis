using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class Party : BaseEntity, IChangingDate
{
    public string PartyName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Description { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
    public int? RoomId { get; set; }
    public SubscriptionType? SubscriptionType { get; set; }
    public ICollection<Room> Rooms { get; set; } = [];
    
    public ICollection<MentionPartyMap> MentionPartyMaps { get; set; } = [];
    public ICollection<Subscribe> CreatedSubscribes { get; set; } = [];
    public ICollection<Subscribe> SubscribedTo { get; set; } = [];
    public ICollection<PartyInterest> PartyInterests { get; set; } = [];
    public ICollection<PartyPurpose> PartyPurposes { get; set; } = [];
}