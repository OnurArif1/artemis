namespace Artemis.API.Entities;

public class SubscribeGetViewModel
{
    public int Id { get; set; }
    public int CreatedPartyId { get; set; }
    public int SubscriberPartyId { get; set; }
    public DateTime CreateDate { get; set; }
}