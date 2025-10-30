using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;
public class Room : BaseEntity, IChangingDate
{
    public int? TopicId { get; set; }
    public int PartyId { get; set; }
    // public ICollection<Party> Party { get; set; }
    public int? CategoryId { get; set; }
    public string Title { get; set; }
    public double LocationX { get; set; }
    public double LocationY { get; set; }
    public RoomType RoomType { get; set; }
    public double LifeCycle { get; set; }
    public double ChannelId { get; set; }
    public string ReferenceId { get; set; }
    public int Upvote { get; set; }
    public int Downvote { get; set; }
    public DateTime CreateDate { get; set; }

    // public ICollection<Category?> Category { get; set; }
}