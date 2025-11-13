namespace Artemis.API.Services;

public class MessageFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? RoomId { get; set; }
    public int? PartyId { get; set; }
}

