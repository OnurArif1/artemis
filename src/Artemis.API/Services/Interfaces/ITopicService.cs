using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ITopicService
{
    ValueTask<TopicListViewModel> GetList(TopicFilterViewModel filterViewModel);
    ValueTask<TopicGetViewModel?> GetById(int id);
    ValueTask Create(CreateOrUpdateTopicViewModel viewModel);
    ValueTask Update(CreateOrUpdateTopicViewModel viewModel);
    ValueTask Delete(int id);
}