using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class OrganizationService : IOrganizationService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IQueryable<Organization> query;

    public OrganizationService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.Organizations.AsQueryable();
    }

    public async ValueTask<OrganizationListViewModel> GetList(OrganizationFilterViewModel filterViewModel)
    {
        var count = await query.CountAsync();

        var organizations = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new OrganizationResultViewModel
            {
                Id = r.Id,
                PartyName = r.PartyName,
                PartyType = r.PartyType,
                IsBanned = r.IsBanned,
                DeviceId = r.DeviceId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new OrganizationListViewModel
        {
            Count = count,
            ResultViewModels = organizations
        };
    }

    public async ValueTask<OrganizationGetViewModel?> GetById(int id)
    {
        var organization = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (organization is not null)
        {
            return new OrganizationGetViewModel
            {
                Id = organization.Id,
                PartyName = organization.PartyName,
                PartyType = organization.PartyType,
                IsBanned = organization.IsBanned,
                DeviceId = organization.DeviceId,
                CreateDate = organization.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdateOrganizationViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (string.IsNullOrWhiteSpace(viewModel.PartyName))
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "PartyName cannot be null or white space.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.NullOrWhiteSpace;

            return resultViewModel;
        }

        await _artemisDbContext.Organizations.AddAsync(new Organization
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId
        });
        _artemisDbContext.SaveChanges();

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Update(CreateOrUpdateOrganizationViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var organization = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (organization is not null)
        {
            if (organization.PartyName != viewModel.PartyName)
                organization.PartyName = viewModel.PartyName;

            if (organization.PartyType != viewModel.PartyType)
                organization.PartyType = viewModel.PartyType;

            if (organization.IsBanned != viewModel.IsBanned)
                organization.IsBanned = viewModel.IsBanned;

            if (organization.DeviceId != viewModel.DeviceId)
                organization.DeviceId = viewModel.DeviceId;

            await _artemisDbContext.SaveChangesAsync();
        }    

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Delete(int id)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var organization = await _artemisDbContext.Organizations.FirstOrDefaultAsync(i => i.Id == id);
        if (organization is not null)
        {
            _artemisDbContext.Organizations.Remove(organization);
            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}