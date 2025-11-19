namespace Artemis.API.Entities;
public class Hashtag : BaseEntity, IChangingDate
{
    public string HashtagName { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }

    public ICollection<RoomHashtagMap> RoomHashtagMaps { get; set; } = [];
    public ICollection<CategoryHashtagMap> CategoryHashtagMaps { get; set; } = [];
    public ICollection<TopicHashtagMap> TopicHashtagMaps { get; set; } = new List<TopicHashtagMap>();
}