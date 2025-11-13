using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IMentionService
{
    ValueTask<MentionListViewModel> GetList(MentionFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateMentionViewModel viewModel);
    ValueTask Update(CreateOrUpdateMentionViewModel viewModel);
    ValueTask<ResultMentionLookupViewModel> GetLookup(GetLookupMentionViewModel viewModel);
    ValueTask Delete(int id);
}

