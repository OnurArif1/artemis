namespace Artemis.API.Entities;
public class Comment : BaseEntity, IChangingDate
{
    public int TopicId { get; set; }
    public Topic? Topic { get; set; }
    public int PartyId { get; set; }
    public Party? Party { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}