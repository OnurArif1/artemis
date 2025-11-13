using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IHashtagService
{
    ValueTask<HashtagListViewModel> GetList(HashtagFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateHashtagViewModel viewModel);
    ValueTask Update(CreateOrUpdateHashtagViewModel viewModel);
    ValueTask<ResultHashtagLookupViewModel> GetHashtagLookup(GetLookupHashtagViewModel viewModel);
    ValueTask Delete(int id);
}