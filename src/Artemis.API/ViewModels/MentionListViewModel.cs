namespace Artemis.API.Services;

public class MentionListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<MentionResultViewModel> ResultViewModels { get; set; } = new List<MentionResultViewModel>();
}

public class MentionResultViewModel
{
    public int Id { get; set; }
    public int? RoomId { get; set; }
    public int? MessageId { get; set; }
    public int? CommentId { get; set; }
    public int? TopicId { get; set; }
    public DateTime CreateDate { get; set; }
}

