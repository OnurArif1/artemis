namespace Artemis.API.Services;

public class MessageListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<MessageResultViewModel> ResultViewmodels { get; set; } = new List<MessageResultViewModel>();
}

public class MessageResultViewModel
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public int PartyId { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}

