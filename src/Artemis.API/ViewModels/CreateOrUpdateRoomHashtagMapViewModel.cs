namespace Artemis.API.Services;

public class CreateOrUpdateRoomHashtagMapViewModel
{
    public int? Id { get; set; } = null;
    public int RoomId { get; set; }
    public int HashtagId { get; set; }
}
