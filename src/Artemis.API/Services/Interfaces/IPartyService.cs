using Artemis.API.Entities.Enums;

namespace Artemis.API.Services.Interfaces;

public interface IPartyService
{
    ValueTask<PartyListViewModel> GetList(PartyFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdatePartyViewModel viewModel);
    ValueTask Update(CreateOrUpdatePartyViewModel viewModel);
    ValueTask UpdateByEmail(string email, string? partyName, string? description);
    ValueTask UpdateSubscriptionByEmail(string email, SubscriptionType subscriptionType);
    ValueTask<ResultPartyLookupViewModel> GetPartyLookup(GetLookupPartyViewModel viewModel);
    ValueTask<PartyProfileByEmailViewModel?> GetProfileByEmailAsync(string email);
    ValueTask Delete(int id);
}