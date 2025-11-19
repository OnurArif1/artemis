using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;
public class Room : BaseEntity, IChangingDate
{
    public int? TopicId { get; set; }
    public Topic? Topic { get; set; }
    public int? PartyId { get; set; }
    public ICollection<Party> Parties { get; set; } = new List<Party>();
    public int? CategoryId { get; set; }
    public Category? Category { get; set; }
    public string Title { get; set; } = string.Empty;
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public double ChannelId { get; set; }
    public string ReferenceId { get; set; } = string.Empty;
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }

    public ICollection<RoomHashtagMap> RoomHashtagMaps { get; set; } = [];
    public ICollection<Message> Messages { get; set; } = new List<Message>();

}