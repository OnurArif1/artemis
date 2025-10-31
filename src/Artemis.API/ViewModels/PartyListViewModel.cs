using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class PartyListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<PartyResultViewModel> ResultViewmodels { get; set; } = new List<PartyResultViewModel>();
}

public class PartyResultViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}


