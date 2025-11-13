namespace Artemis.API.Services.Interfaces;

public interface ITopicHashtagMapService
{
    ValueTask<TopicHashtagMapListViewModel> GetList(TopicHashtagMapFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateTopicHashtagMapViewModel viewModel);
    ValueTask Update(CreateOrUpdateTopicHashtagMapViewModel viewModel);
    ValueTask<ResultTopicHashtagMapLookupViewModel> GetLookup(GetLookupTopicHashtagMapViewModel viewModel);
    ValueTask Delete(int id);
}

