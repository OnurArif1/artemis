namespace Artemis.API.Services;

public class MentionPartyMapListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<MentionPartyMapResultViewModel> ResultViewModels { get; set; } = new List<MentionPartyMapResultViewModel>();
}

public class MentionPartyMapResultViewModel
{
    public int Id { get; set; }
    public int MentionId { get; set; }
    public int PartyId { get; set;}
}