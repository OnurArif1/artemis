namespace Artemis.API.Services;

public class TopicHashtagMapLookupViewModel
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    public int HashtagId { get; set; }
}

public class ResultTopicHashtagMapLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<TopicHashtagMapLookupViewModel>? ViewModels { get; set; }
}

