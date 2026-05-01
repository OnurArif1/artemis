namespace Artemis.API.Services;

public class CommentFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? TopicId { get; set; }
    public int? PartyId { get; set; }

    /// <summary>
    /// true ise <see cref="ParticipatingPartyId"/> en az bir yorum attığı her konu için,
    /// konudaki herhangi bir göndericiye ait en güncel yorumu döndürür.
    /// </summary>
    public bool LatestInTopicsWhereParticipated { get; set; }

    /// <summary>
    /// <see cref="LatestInTopicsWhereParticipated"/> için zorunlu: katılımcı party id.
    /// </summary>
    public int? ParticipatingPartyId { get; set; }
}