using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class CreateOrUpdateCategoryViewModel
{
    public int? Id { get; set; } = null;
    public string Title { get; set; }
    public DateTime CreateDate { get; set; }
}