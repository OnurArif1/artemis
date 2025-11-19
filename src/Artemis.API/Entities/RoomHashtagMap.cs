namespace Artemis.API.Entities;
public class RoomHashtagMap : BaseEntity, IChangingDate
{
    public int RoomId { get; set; }
    public Room? Room { get; set; }
    public int HashtagId { get; set; }
    public Hashtag? Hashtag { get; set; }
    public DateTime CreateDate { get; set; }
}