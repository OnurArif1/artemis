namespace Artemis.API.ViewModels;
public class AddPartyToRoomViewModel
{
    public int RoomId { get; set; }
    public int PartyId { get; set; } // Backward compatibility için
    public List<int>? PartyIds { get; set; } // Çoklu davet için
}