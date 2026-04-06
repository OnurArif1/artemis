namespace Artemis.API.Services;

public class TopicFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }

    /// <summary>Başlıkta içerir araması (mobil / liste).</summary>
    public string? Title { get; set; }
}