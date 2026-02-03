namespace Artemis.API.Services;

public class CommentFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? TopicId { get; set; }
}