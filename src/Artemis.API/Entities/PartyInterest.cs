namespace Artemis.API.Entities;

public class PartyInterest : BaseEntity, IChangingDate
{
    public int InterestId { get; set; }
    public Interest? Interest { get; set; }
    public int PartyId { get; set; }
    public Party? Party { get; set; }
    public DateTime CreateDate { get; set; }
}
