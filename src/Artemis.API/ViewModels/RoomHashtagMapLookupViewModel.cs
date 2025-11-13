namespace Artemis.API.Services;

public class RoomHashtagMapLookupViewModel
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public int HashtagId { get; set; }
}

public class ResultRoomHashtagMapLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<RoomHashtagMapLookupViewModel>? ViewModels { get; set; }
}