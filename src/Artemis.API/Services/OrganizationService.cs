using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class OrganizationService : IOrganizationService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public OrganizationService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateOrganizationViewModel viewModel)
    {
        var organization = new Organization()
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId
        };
        await _artemisDbContext.Organizations.AddAsync(party);

        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<OrganizationListViewModel> GetList(OrganizationFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Organizations.AsQueryable();
        var count = await query.CountAsync();

        var organizations = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new PartyResultViewModel
            {
                Id = r.Id,
                PartyName = r.PartyName,
                PartyType = r.PartyType,
                IsBanned = r.IsBanned,
                DeviceId = r.DeviceId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new OrganizationResultViewModel
        {
            Count = count,
            ResultViewModels = organizations
        };
    }

    public async ValueTask Update(CreateOrUpdateOrganizationViewModel viewModel)
    {
        var query = _artemisDbContext.Organizations.AsQueryable();
        var organization = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (organization is not null)
        {
            organization.PartyName = viewModel.PartyName;
            organization.PartyType = viewModel.PartyType;
            organization.IsBanned = viewModel.IsBanned;
            organization.DeviceId = viewModel.DeviceId;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask Delete(int id)
    {
        var organization = await _artemisDbContext.Organizations.FirstOrDefaultAsync(i => i.Id == id);
        
        if (organization is not null)
        {
            _artemisDbContext.Organizations.Remove(organization);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}