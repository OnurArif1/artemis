using System.Security.AccessControl;

namespace Artemis.API.Entities;
public class Subscribe : BaseEntity
{
    public int CreatedPartyId { get; set; }
    public virtual Party CreatedParty { get; set; }
    public int SubscriberPartyId { get; set; }
    public virtual Party SubscriberParty { get; set; }
}