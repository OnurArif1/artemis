namespace Artemis.API.Entities;
public class Message : BaseEntity, IChangingDate
{
    public int RoomId { get; set; }
    public Room? Room { get; set; }
    public int PartyId { get; set; }
    public Party? Party { get; set; }
    public string Content { get; set; } = string.Empty;
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}