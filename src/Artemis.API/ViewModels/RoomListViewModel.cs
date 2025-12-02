using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class RoomListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<RoomResultViewModel> ResultViewModels { get; set; } = new List<RoomResultViewModel>();
}

public class RoomResultViewModel
{
    public int Id { get; set; }
    public int? TopicId { get; set; }
    public string? TopicTitle { get; set; }
    public string Title { get; set; }
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public string ChannelId { get; set; } = string.Empty;
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }
    public int? PartyId { get; set; }
    public string? PartyName { get; set; }
    public List<PartyInfo> Parties { get; set; } = new List<PartyInfo>();
    public string? CategoryTitle { get; set; }
}

public class PartyInfo
{
    public int Id { get; set; }
    public string PartyName { get; set; } = string.Empty;
}