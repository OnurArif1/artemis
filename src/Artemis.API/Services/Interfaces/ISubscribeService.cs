using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ISubscribeService
{
    ValueTask<SubscribeListViewModel> GetList(SubscribeFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateSubscribeViewModel viewModel);
    ValueTask Update(CreateOrUpdateSubscribeViewModel viewModel);
    ValueTask Delete(int id);
}