namespace Artemis.API.Services;

public class MessageFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? RoomId { get; set; }
    public int? PartyId { get; set; }

    /// <summary>
    /// true ise <see cref="ParticipatingPartyId"/> en az bir mesaj attığı her oda için,
    /// odadaki herhangi bir göndericiye ait en güncel mesajı döndürür (sohbet listesi önizlemesi).
    /// </summary>
    public bool LatestInRoomsWhereParticipated { get; set; }

    /// <summary>
    /// <see cref="LatestInRoomsWhereParticipated"/> için zorunlu: katılımcı party id.
    /// </summary>
    public int? ParticipatingPartyId { get; set; }
}

