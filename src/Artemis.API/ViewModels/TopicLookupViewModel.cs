namespace Artemis.API.Services;

public class TopicLookupViewModel
{
    public int? TopicId { get; set; }
    public string? Title { get; set; }
}

public class ResultTopicLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<TopicLookupViewModel>? ViewModels { get; set; }
}

