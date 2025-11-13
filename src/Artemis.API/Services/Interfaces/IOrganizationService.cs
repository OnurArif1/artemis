using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IOrganizationService
{
    ValueTask<OrganizationListViewModel> GetList(OrganizationFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateOrganizationViewModel viewModel);
    ValueTask Update(CreateOrUpdateOrganizationViewModel viewModel);
    ValueTask Delete(int id);
}