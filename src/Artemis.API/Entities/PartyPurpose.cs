using Artemis.API.Entities.Enums;

namespace Artemis.API.Entities;

public class PartyPurpose : BaseEntity, IChangingDate
{
    public PartyPurposeType PurposeType { get; set; }
    public int PartyId { get; set; }
    public Party? Party { get; set; }
    public DateTime CreateDate { get; set; }
}
