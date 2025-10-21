namespace Artemis.API.Entities;
public class BaseEntity
{
    public int Id { get; set; }
    public DateTime CreateDate { get; set; }
    public string? Comment { get; set; }
}