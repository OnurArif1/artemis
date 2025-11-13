using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IPersonService
{
    ValueTask<PersonListViewModel> GetList(PersonFilterViewModel filterViewModel);
    ValueTask<PersonGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdatePersonViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdatePersonViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
}