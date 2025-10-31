using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IPartyService
{
    ValueTask<PartyListViewModel> GetList(PartyFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdatePartyViewModel viewModel);
    ValueTask Update(CreateOrUpdatePartyViewModel viewModel);
}