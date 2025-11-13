using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class PersonListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<PersonResultViewModel> ResultViewModels { get; set; } = new();
}

public class PersonResultViewModel
{
    public int Id { get; set; }
    public string PartyName { get; set; }
    public PartyType PartyType { get; set; }
    public bool IsBanned { get; set; }
    public int DeviceId { get; set; }
    public DateTime CreateDate { get; set; }
}