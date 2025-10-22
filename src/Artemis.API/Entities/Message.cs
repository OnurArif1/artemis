namespace Artemis.API.Entities;
public class Message : BaseEntity
{
    public int RoomId { get; set; }
    public int PartyId { get; set; }
    public virtual Party Party { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public virtual Room Room { get; set; }
    public DateTime CreateDate { get; set; }
}