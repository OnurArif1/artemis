using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class PartyLookupViewModel
{
    public int? PartyId { get; set; }
    public string? PartyName { get; set; }
}

public class ResultPartyLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<PartyLookupViewModel>? ViewModels { get; set; }
}