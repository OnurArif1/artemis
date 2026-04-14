namespace Artemis.API.Services;

public class RoomFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public string? Title { get; set; }
    public int? TopicId { get; set; }
    public double? UserLatitude { get; set; }
    public double? UserLongitude { get; set; }
    public string? UserEmail { get; set; }

    /// <summary>
    /// Sohbet başlat (+): tüm odalar üzerinden menzil içi yakınlar + eksik kısım Upvote ile tamamlanır (PageSize = hedef adet, varsayılan 20).
    /// </summary>
    public bool StartChatPickerMode { get; set; }

    /// <summary>
    /// Bool query bazen bağlanmayabildiği için yedek: <c>startChat</c> ise StartChatPickerMode ile aynı.
    /// </summary>
    public string? ListMode { get; set; }
}