using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ISubscribeService
{
    ValueTask<SubscribeListViewModel> GetList(SubscribeFilterViewModel filterViewModel);
    ValueTask<SubscribeGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdateSubscribeViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdateSubscribeViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
}