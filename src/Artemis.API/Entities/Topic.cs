using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class Topic : BaseEntity, IChangingDate
{
    public int? PartyId { get; set; }
    public Party? Party { get; set; }
    public string Title { get; set; } = string.Empty;
    public RoomType Type { get; set; }
    public double? LocationX { get; set; }
    public double? LocationY { get; set; }
    public int CategoryId { get; set; }
    public Category? Category { get; set; }
    public int? MentionId { get; set; }
    public Mention? Mention { get; set; }
    public int? Upvote { get; set; }
    public int? Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }

    public ICollection<Room> Rooms { get; set; } = new List<Room>();
    public ICollection<TopicHashtagMap> TopicHashtagMaps { get; set; } = new List<TopicHashtagMap>();
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
}