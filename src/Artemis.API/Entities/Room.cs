using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;
public class Room : BaseEntity, IChangingDate
{
    public int? TopicId { get; set; }
    public Topic? Topic { get; set; }
    public int? PartyId { get; set; }
    public int? CategoryId { get; set; }
    public Category? Category { get; set; }
    public string Title { get; set; } = string.Empty;
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public string ChannelId { get; set; } = string.Empty;
    public string ReferenceId { get; set; } = string.Empty;
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }
    public double? RoomRange { get; set; }
    public SubscriptionType? SubscriptionType { get; set; }

    public ICollection<RoomHashtagMap> RoomHashtagMaps { get; set; } = [];
    public ICollection<Message> Messages { get; set; } = new List<Message>();
    public ICollection<Party> Parties { get; set; } = [];

}