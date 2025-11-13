namespace Artemis.API.Services;

public class MentionFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? RoomId { get; set; }
    public int? MessageId { get; set; }
    public int? CommentId { get; set; }
    public int? TopicId { get; set; }
}

