namespace Artemis.API.Entities;

public class Interest : BaseEntity, IChangingDate
{
    public string Name { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
    
    public ICollection<PartyInterest> PartyInterests { get; set; } = new List<PartyInterest>();
}
