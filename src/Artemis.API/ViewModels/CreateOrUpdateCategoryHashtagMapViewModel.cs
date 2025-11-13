namespace Artemis.API.Services;

public class CreateOrUpdateCategoryHashtagMapViewModel
{
    public int? Id { get; set; } = null;
    public int CategoryId { get; set; }
    public int HashtagId { get; set; }
}

