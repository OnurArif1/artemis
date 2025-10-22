namespace Artemis.API.Entities;
public class RoomHashtagMap : BaseEntity
{
    public int RoomId { get; set; }
    public int HashtagId { get; set; }

    public virtual Room Room { get; set; }
    public virtual Hashtag Hashtag { get; set; }
    public DateTime CreateDate { get; set; }
}