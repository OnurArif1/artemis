using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class GetLookupTopicViewModel
{
    public int? TopicId { get; set; }
    public string? SearchText { get; set; }
    public TopicLookupSearchType? TopicLookupSearchType { get; set; }
}

