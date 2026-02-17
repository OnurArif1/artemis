namespace Artemis.API.Services;

public class CategoryListViewModel
{
    public int? Count { get; set; }
    public IEnumerable<CategoryResultViewModel> ResultViewmodels { get; set; } = new List<CategoryResultViewModel>();
}

public class CategoryResultViewModel
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
}


