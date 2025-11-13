using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CommentListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<CommentResultViewModel> ResultViewModels { get; set; } = new List<CommentResultViewModel>();
}

public class CommentResultViewModel
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    public int PartyId { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}