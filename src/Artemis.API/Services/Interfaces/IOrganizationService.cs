using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IOrganizationService
{
    ValueTask<OrganizationListViewModel> GetList(OrganizationFilterViewModel filterViewModel);
    ValueTask<OrganizationGetViewModel?> GetById(int id);
    ValueTask<ResultViewModel> Create(CreateOrUpdateOrganizationViewModel viewModel);
    ValueTask<ResultViewModel> Update(CreateOrUpdateOrganizationViewModel viewModel);
    ValueTask<ResultViewModel> Delete(int id);
}