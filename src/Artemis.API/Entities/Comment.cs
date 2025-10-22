namespace Artemis.API.Entities;
public class Comment : BaseEntity
{
    public int TopicId { get; set; }
    public virtual Topic Topic { get; set; }
    public int PartyId { get; set; }
    public virtual Party Party { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}