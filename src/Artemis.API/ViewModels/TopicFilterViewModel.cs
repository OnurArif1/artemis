namespace Artemis.API.Services;

public class TopicFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public string? Title { get; set; }
    public bool SortByUpvoteDesc { get; set; }
}