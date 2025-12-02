namespace Artemis.API.Services;

public class CreateOrUpdateCategoryViewModel
{
    public int? Id { get; set; } = null;
    public string Title { get; set; } = string.Empty;
    public DateTime CreateDate { get; set; }
}