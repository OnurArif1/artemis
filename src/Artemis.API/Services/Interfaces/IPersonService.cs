using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IPersonService
{
    ValueTask<PersonListViewModel> GetList(PersonFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdatePersonViewModel viewModel);
    ValueTask Update(CreateOrUpdatePersonViewModel viewModel);
    ValueTask Delete(int id);
}