namespace Artemis.API.Entities;
public class Hashtag : BaseEntity, IChangingDate
{
    public string HashtagName { get; set; }
    public DateTime CreateDate { get; set; }
}