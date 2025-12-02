using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class OrganizationListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<OrganizationResultViewModel> ResultViewModels { get; set; } = new List<OrganizationResultViewModel>();
}

public class OrganizationResultViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; } = string.Empty;
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}