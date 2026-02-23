
namespace Artemis.API.Entities;

public class AppSubscription : BaseEntity, IChangingDate
{
    public int UserId { get; set; }
    public Party? UserParty { get; set; }
    public int AppSubscriptionTypePriceId { get; set; }
    public AppSubscriptionTypePrices? AppSubscriptionTypePrice { get; set; }
    public DateTime CreateDate { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
}