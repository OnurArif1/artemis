namespace Artemis.API.Entities;
public class Category : BaseEntity, IChangingDate
{
    public string Title { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
    public ICollection<Room> Rooms { get; set; } = [];

    public ICollection<CategoryHashtagMap> CategoryHashtagMaps { get; set; } = [];
}