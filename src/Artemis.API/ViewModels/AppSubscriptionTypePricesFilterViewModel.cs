using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class AppSubscriptionTypePricesFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public SubscriptionType? SubscriptionType { get; set; }
    public CurrencyType? PriceCurrencyType { get; set; }
}
