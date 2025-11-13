namespace Artemis.API.Services;

public class CategoryHashtagMapLookupViewModel
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public int HashtagId { get; set; }
}

public class ResultCategoryHashtagMapLookupViewModel
{
    public int? Count { get; set; }
    public IEnumerable<CategoryHashtagMapLookupViewModel>? ViewModels { get; set; }
}

