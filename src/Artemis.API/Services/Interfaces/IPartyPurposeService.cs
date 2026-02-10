using Artemis.API.Entities.Enums;

namespace Artemis.API.Services.Interfaces;

public interface IPartyPurposeService
{
    ValueTask SavePartyPurposesAsync(string email, List<PartyPurposeType> purposeTypes);
}
