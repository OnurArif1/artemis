using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class RoomListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<RoomResultViewmodel> ResultViewmodels { get; set; } = new List<RoomResultViewmodel>();
}

public class RoomResultViewmodel
{
    public int Id { get; set; }
    public string Title { get; set; }
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }
}