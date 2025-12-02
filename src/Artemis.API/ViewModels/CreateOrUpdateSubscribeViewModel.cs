namespace Artemis.API.Services;

public class CreateOrUpdateSubscribeViewModel
{
    public int? Id { get; set; }
    public int CreatedPartyId { get; set; }
    public int SubscriberPartyId { get; set; }
}