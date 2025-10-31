using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface ICategoryService
{
    ValueTask<CategoryListViewModel> GetList(CategoryFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateCategoryViewModel viewModel);
    ValueTask Update(CreateOrUpdateCategoryViewModel viewModel);
    ValueTask<ResultCategoryLookupViewModel> GetCategoryLookup(GetLookupCategoryViewModel viewModel);
}