namespace Artemis.API.Services;

public class TopicFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }

    /// <summary>Başlıkta içerir araması (mobil / liste).</summary>
    public string? Title { get; set; }

    /// <summary>True ise önce Upvote (yıldız) azalan, sonra oluşturma tarihi.</summary>
    public bool SortByUpvoteDesc { get; set; }
}