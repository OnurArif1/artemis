using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreateOrUpdateRoomViewModel
{
    public int? Id { get; set; } = null;
     public int? TopicId { get; set; }
    public int PartyId { get; set; }
    public int? CategoryId { get; set; }
    public string Title { get; set; } = string.Empty;
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public string ChannelId { get; set; } = string.Empty;
    public string ReferenceId { get; set; } = string.Empty;
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }
}