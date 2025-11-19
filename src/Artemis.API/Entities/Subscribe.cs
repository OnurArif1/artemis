using System.Security.AccessControl;

namespace Artemis.API.Entities;

public class Subscribe : BaseEntity, IChangingDate
{
    public int CreatedPartyId { get; set; }
    public Party? CreatedParty { get; set; }
    public int SubscriberPartyId { get; set; }
    public Party? SubscriberParty { get; set; }
    public DateTime CreateDate { get; set; }
}