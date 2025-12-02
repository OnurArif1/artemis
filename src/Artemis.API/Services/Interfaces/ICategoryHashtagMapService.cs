namespace Artemis.API.Services.Interfaces;

public interface ICategoryHashtagMapService
{
    ValueTask<CategoryHashtagMapListViewModel> GetList(CategoryHashtagMapFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateCategoryHashtagMapViewModel viewModel);
    ValueTask Update(CreateOrUpdateCategoryHashtagMapViewModel viewModel);
    ValueTask<ResultCategoryHashtagMapLookupViewModel> GetLookup(GetLookupCategoryHashtagMapViewModel viewModel);
    ValueTask Delete(int id);
}

