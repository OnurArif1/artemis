namespace Artemis.API.Entities;
public class Mention : BaseEntity
{
    public int? RoomId { get; set; }
    public virtual Room? Room { get; set; }
    public int? MessageId { get; set; }
    public virtual Message? Message { get; set; }
    public int? CommandId { get; set; }
    public virtual Command? Command { get; set; }
    public int? TopicId { get; set; }
    public virtual Topic? Topic { get; set; }
    
}