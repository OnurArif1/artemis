namespace Artemis.API.Services.Interfaces;

public interface IAppSubscriptionTypePricesService
{
    ValueTask<AppSubscriptionTypePricesListViewModel> GetList(AppSubscriptionTypePricesFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel);
    ValueTask Update(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel);
    ValueTask Delete(int id);
}
