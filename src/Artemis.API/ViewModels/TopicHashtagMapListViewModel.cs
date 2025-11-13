namespace Artemis.API.Services;

public class TopicHashtagMapListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<TopicHashtagMapResultViewModel> ResultViewModels { get; set; } = new List<TopicHashtagMapResultViewModel>();
}

public class TopicHashtagMapResultViewModel
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    public int HashtagId { get; set; }
    public DateTime CreateDate { get; set; }
}

