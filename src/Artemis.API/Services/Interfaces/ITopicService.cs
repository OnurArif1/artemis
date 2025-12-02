namespace Artemis.API.Services.Interfaces;

public interface ITopicService
{
    ValueTask<TopicListViewModel> GetList(TopicFilterViewModel filterViewModel);
    ValueTask<TopicGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdateTopicViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdateTopicViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
    ValueTask<ResultTopicLookupViewModel> GetTopicLookup(GetLookupTopicViewModel viewModel);
}
