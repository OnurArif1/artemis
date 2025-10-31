namespace Artemis.API.Services;

public class CategoryLookupViewModel
{
    public int? CategoryId { get; set; }
    public string? Title { get; set; }
}

public class ResultCategoryLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<CategoryLookupViewModel>? ViewModels { get; set; }
}
