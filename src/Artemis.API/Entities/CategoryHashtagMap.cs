namespace Artemis.API.Entities;
public class CategoryHashtagMap : BaseEntity, IChangingDate
{
    public int HashtagId { get; set; }
    public Hashtag? Hashtag { get; set; }
    public Category? Category { get; set; }
    public int CategoryId { get; set; }
    public DateTime CreateDate { get; set; }
}