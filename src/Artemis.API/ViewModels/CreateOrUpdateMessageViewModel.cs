namespace Artemis.API.Services;

public class CreateOrUpdateMessageViewModel
{
    public int? Id { get; set; } = null;
    public int RoomId { get; set; }
    public int PartyId { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime? LastUpdateDate { get; set; }
    public DateTime? CreateDate { get; set; }
}

