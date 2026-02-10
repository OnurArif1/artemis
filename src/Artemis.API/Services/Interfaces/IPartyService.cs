namespace Artemis.API.Services.Interfaces;

public interface IPartyService
{
    ValueTask<PartyListViewModel> GetList(PartyFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdatePartyViewModel viewModel);
    ValueTask Update(CreateOrUpdatePartyViewModel viewModel);
    ValueTask UpdateByEmail(string email, string partyName, string? description);
    ValueTask<ResultPartyLookupViewModel> GetPartyLookup(GetLookupPartyViewModel viewModel);
    ValueTask Delete(int id);
}