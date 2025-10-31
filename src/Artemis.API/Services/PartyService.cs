using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PartyService : IPartyService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public PartyService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdatePartyViewModel viewModel)
    {
        var party = new Party()
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId,
            CreateDate = viewModel.CreateDate
        };
        await _artemisDbContext.Parties.AddAsync(party);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<PartyListViewModel> GetList(PartyFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Parties.AsQueryable();
        var count = await query.CountAsync();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            query = query.Where(x => x.PartyName.Contains(filterViewModel.Title));
        }

        var parties = await query.OrderByDescending(i => i.CreateDate)
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

        return new PartyListViewModel
        {
            Count = count,
            ResultViewmodels = parties
        };
    }

    public async ValueTask Update(CreateOrUpdatePartyViewModel viewModel)
    {
        var query = _artemisDbContext.Parties.AsQueryable();
        var party = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (party is not null)
        {
            party.PartyName = viewModel.PartyName;
            party.PartyType = viewModel.PartyType;
            party.IsBanned = viewModel.IsBanned;
            party.DeviceId = viewModel.DeviceId;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }
    

}