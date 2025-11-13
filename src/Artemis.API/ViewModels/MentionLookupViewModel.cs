namespace Artemis.API.Services;

public class MentionLookupViewModel
{
    public int Id { get; set; }
    public int? RoomId { get; set; }
    public int? MessageId { get; set; }
    public int? CommentId { get; set; }
    public int? TopicId { get; set; }
}

public class ResultMentionLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<MentionLookupViewModel>? ViewModels { get; set; }
}

