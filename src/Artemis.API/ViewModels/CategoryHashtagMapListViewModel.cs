namespace Artemis.API.Services;

public class CategoryHashtagMapListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<CategoryHashtagMapResultViewModel> ResultViewModels { get; set; } = new List<CategoryHashtagMapResultViewModel>();
}

public class CategoryHashtagMapResultViewModel
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public int HashtagId { get; set; }
    public DateTime CreateDate { get; set; }
}

