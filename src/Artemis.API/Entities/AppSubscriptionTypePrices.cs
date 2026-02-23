
using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class AppSubscriptionTypePrices : BaseEntity, IChangingDate
{
    public SubscriptionType SubscriptionType { get; set; }
    public decimal Price { get; set; }
    public CurrencyType PriceCurrencyType { get; set; }
    public AppSubscriptionPeriodType? AppSubscriptionPeriodType { get; set; }
    public DateTime CreateDate { get;set; }
    public DateTime? ThruDate { get; set; }
}