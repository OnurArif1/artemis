namespace Artemis.API.Entities;
public class TopicHashtagMap : BaseEntity, IChangingDate
{
    public int TopicId { get; set; }
    public Topic? Topic { get; set; } 
    public int HashtagId { get; set; }
    public Hashtag? Hashtag { get; set; }
    public DateTime CreateDate { get; set; }
}