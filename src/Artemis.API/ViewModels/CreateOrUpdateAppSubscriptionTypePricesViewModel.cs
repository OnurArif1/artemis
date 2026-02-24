using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreateOrUpdateAppSubscriptionTypePricesViewModel
{
    public int? Id { get; set; }
    public SubscriptionType SubscriptionType { get; set; }
    public decimal Price { get; set; }
    public CurrencyType PriceCurrencyType { get; set; }
    public AppSubscriptionPeriodType? AppSubscriptionPeriodType { get; set; }
}
