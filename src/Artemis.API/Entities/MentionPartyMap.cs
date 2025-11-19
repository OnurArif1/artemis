namespace Artemis.API.Entities;
public class MentionPartyMap : BaseEntity, IChangingDate
{
    public int MentionId { get; set; }
    public Mention? Mention { get; set; }
    public int PartyId { get; set; }
    public Party? Party { get; set; }
    public DateTime CreateDate { get; set; }
}