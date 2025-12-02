namespace Artemis.API.Services.Interfaces;

public interface IMentionPartyMapService
{
    ValueTask<MentionPartyMapListViewModel> GetList(MentionPartyMapFilterViewModel filterViewModel);
    ValueTask<MentionPartyMapGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdateMentionPartyMapViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdateMentionPartyMapViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
}