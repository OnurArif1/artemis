namespace Artemis.API.Services;

public class CreateOrUpdateTopicHashtagMapViewModel
{
    public int? Id { get; set; } = null;
    public int TopicId { get; set; }
    public int HashtagId { get; set; }
}
