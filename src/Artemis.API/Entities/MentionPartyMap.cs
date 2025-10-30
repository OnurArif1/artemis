namespace Artemis.API.Entities;
public class MentionPartyMap : BaseEntity, IChangingDate
{
    public int MentionId { get; set; }
    public virtual Mention Mention { get; set; }
    public int PartyId { get; set; }
    public virtual Party Party { get; set; }
    public DateTime CreateDate { get; set; }
}