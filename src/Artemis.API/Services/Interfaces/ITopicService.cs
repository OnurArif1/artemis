namespace Artemis.API.Services.Interfaces;

public interface ITopicService
{
    ValueTask<ResultTopicLookupViewModel> GetTopicLookup(GetLookupTopicViewModel viewModel);
}

