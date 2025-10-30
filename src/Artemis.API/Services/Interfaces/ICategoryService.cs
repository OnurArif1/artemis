using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ICategoryService
{
    ValueTask<IEnumerable<CategoryGetViewModel>> GetList(CategoryFilterViewModel filterViewModel);
    ValueTask Create(Category category);
    ValueTask<int?> GetCategoryIdByName(string categoryName);
    ValueTask<string?> GetCategoryNameById(int categoryId);
}