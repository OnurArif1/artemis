namespace Artemis.API.Services;

public class CommentFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public int? TopicId { get; set; }
    /// <summary>Kullanıcının yazdığı yorumlar (konu sohbetleri geçmişi).</summary>
    public int? PartyId { get; set; }
}