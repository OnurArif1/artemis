namespace Artemis.API.Entities;
public class Category : BaseEntity, IChangingDate
{
    public string Title { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
    public int? RoomId { get; set; }
    public Room? Room { get; set; }

    public ICollection<CategoryHashtagMap> CategoryHashtagMaps { get; set; } = [];
}