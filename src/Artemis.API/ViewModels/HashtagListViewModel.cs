namespace Artemis.API.Services;
public class HashtagListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<HashtagResultViewModel> ResultViewmodels { get; set; } = new List<HashtagResultViewModel>();
}

public class HashtagResultViewModel
{
    public int Id { get; set; }
    public string HashtagName { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
}
