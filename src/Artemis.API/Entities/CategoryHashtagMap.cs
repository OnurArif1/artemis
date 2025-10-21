namespace Artemis.API.Entities;
public class CategoryHashtagMap : BaseEntity
{
    public int HashtagId { get; set; }

    public virtual Category Category { get; set; }
    public int CategoryId { get; set; }
}