using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IPartyService
{
    ValueTask<IEnumerable<PartyGetViewModel>> GetList(PartyFilterViewModel filterViewModel);
    ValueTask Create(Party party);
}