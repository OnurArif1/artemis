namespace Artemis.API.Services;

public class CreateOrUpdateMentionViewModel
{
    public int? Id { get; set; } = null;
    public int? RoomId { get; set; }
    public int? MessageId { get; set; }
    public int? CommentId { get; set; }
    public int? TopicId { get; set; }
}

