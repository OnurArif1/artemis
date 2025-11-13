using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreateOrUpdateMentionPartyMapViewModel
{
    public int? Id { get; set; }
    public int MentionId { get; set; }
    public int PartyId { get; set; }
    public DateTime CreateDate { get; set; }
}