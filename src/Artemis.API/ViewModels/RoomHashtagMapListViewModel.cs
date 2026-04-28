namespace Artemis.API.Services;

public class RoomHashtagMapListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<RoomHashtagMapResultViewModel> ResultViewModels { get; set; } = [];
}

public class RoomHashtagMapResultViewModel
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public int HashtagId { get; set; }
    public DateTime CreateDate { get; set; }
}
