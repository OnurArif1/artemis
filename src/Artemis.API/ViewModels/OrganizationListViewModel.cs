namespace Artemis.API.Services;

public class OrganizationListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<MentionPartyMapResultViewModel> ResultViewModels { get; set; } = new();
}

public class OrganizationResultViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}