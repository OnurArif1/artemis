using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class TopicGetViewModel
{
    public int Id { get; set; }
    public int PartyId { get; set; }
    public string Title { get; set; }
    public RoomType Type { get; set; }
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public int CategoryId { get; set; }
    public int? MentionId { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime LastUpdateDate { get; set; }
    public DateTime CreateDate { get; set; }
}