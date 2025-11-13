using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class SubscribeService : ISubscribeService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public SubscribeService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateSubscribeViewModel viewModel)
    {
        var subscribe = new Subscribe()
        {
            CreatedPartyId = viewModel.CreatedPartyId,
            SubscriberPartyId = viewModel.SubscriberPartyId
        };

        await _artemisDbContext.Subscribes.AddAsync(subscribe);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<SubscribeListViewModel> GetList(SubscribeFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Subscribes.AsQueryable();
        var count = await query.CountAsync();

        var subscribes = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new SubscribeResultViewModel
            {
                Id = r.Id,
                CreatedPartyId = r.CreatedPartyId,
                SubscriberPartyId = r.SubscriberPartyId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new SubscribeListViewModel
        {
            Count = count,
            ResultViewModels = subscribes
        };
    }

    public async ValueTask Update(CreateOrUpdateSubscribeViewModel viewModel)
    {
        var query = _artemisDbContext.Subscribes.AsQueryable();
        var subscribe = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (subscribe is not null)
        {
            subscribe.CreatedPartyId = viewModel.CreatedPartyId;
            subscribe.SubscriberPartyId = viewModel.SubscriberPartyId;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask Delete(int id)
    {
        var subscribe = await _artemisDbContext.Subscribes.FirstOrDefaultAsync(i => i.Id == id);

        if (subscribe is not null)
        {
            _artemisDbContext.Subscribes.Remove(subscribe);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}