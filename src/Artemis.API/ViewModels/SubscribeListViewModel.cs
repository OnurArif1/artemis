namespace Artemis.API.Services;

public class SubscribeListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<SubscribeResultViewModel> ResultViewModels { get; set; } = [];
}

public class SubscribeResultViewModel
{
    public int Id { get; set; }
    public int CreatedPartyId { get; set; }
    public int SubscriberPartyId { get; set; }
    public DateTime CreateDate { get; set; }
}