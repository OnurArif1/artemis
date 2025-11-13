namespace Artemis.API.Entities;
public class Mention : BaseEntity, IChangingDate
{
    public int? RoomId { get; set; }
    public virtual Room? Room { get; set; }
    public int? MessageId { get; set; }
    public virtual Message? Message { get; set; }
    public int? CommentId { get; set; }
    public new virtual Comment? Comment { get; set; }
    public int? TopicId { get; set; }
    public virtual Topic? Topic { get; set; }
    public DateTime CreateDate { get; set; }    
}