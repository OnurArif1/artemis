using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class SubscribeListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<SubscribeResultViewModel> ResultViewModels { get; set; } = new List<SubscribeResultViewModel>();
}

public class SubscribeResultViewModel
{
    public int Id { get; set; }
    public int CreatedPartyId { get; set; }
    public int SubscriberPartyId { get; set; }
    public DateTime CreateDate { get; set; }
}