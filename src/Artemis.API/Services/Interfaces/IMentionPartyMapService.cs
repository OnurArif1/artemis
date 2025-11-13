using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IMentionPartyMapService
{
    ValueTask<MentionPartyMapViewModel> GetList(MentionPartyMapFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateMentionPartyMapViewModel viewModel);
    ValueTask Update(CreateOrUpdateMentionPartyMapViewModel viewModel);
    ValueTask Delete(int id);
}