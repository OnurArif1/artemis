namespace Artemis.API.Entities;
public class TopicHashtagMap : BaseEntity, IChangingDate
{
    public int TopicId { get; set; }
    public int HashtagId { get; set; }

    public virtual Hashtag Hashtag { get; set; }
    public DateTime CreateDate { get; set; }
}