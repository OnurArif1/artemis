using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ITopicService
{
    ValueTask<TopicListViewModel> GetList(TopicFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateTopicViewModel viewModel);
    ValueTask Update(CreateOrUpdateTopicViewModel viewModel);
    ValueTask Delete(int id);
}