namespace Artemis.API.Entities;
public class Category : BaseEntity, IChangingDate
{
    public string Title { get; set; }
    public DateTime CreateDate { get; set; }
    public int? RoomId { get; set; }
    public Room? Room { get; set; }
}