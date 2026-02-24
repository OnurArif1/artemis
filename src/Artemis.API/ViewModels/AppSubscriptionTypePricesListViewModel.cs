using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class AppSubscriptionTypePricesListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<AppSubscriptionTypePricesResultViewModel> ResultViewmodels { get; set; } = new List<AppSubscriptionTypePricesResultViewModel>();
}

public class AppSubscriptionTypePricesResultViewModel
{
    public int Id { get; set; }
    public SubscriptionType SubscriptionType { get; set; }
    public decimal Price { get; set; }
    public CurrencyType PriceCurrencyType { get; set; }
    public AppSubscriptionPeriodType? AppSubscriptionPeriodType { get; set; }
    public DateTime CreateDate { get; set; }
    public DateTime? ThruDate { get; set; }
}
