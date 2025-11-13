using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class GetLookupPartyViewModel
{
    public int? PartyId { get; set; }
    public string? SearchText { get; set; }
    public PartyLookupSearchType? PartyLookupSearchType { get; set; }
}
