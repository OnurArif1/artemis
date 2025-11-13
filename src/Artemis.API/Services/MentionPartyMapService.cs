using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class MentionPartyMapService : IMentionPartyMapService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public MentionPartyMapService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        var mentionPartyMap = new MentionPartyMap()
        {
            MentionId = viewModel.MentionId,
            PartyId = viewModel.PartyId
        };
        await _artemisDbContext.MentionPartyMaps.AddAsync(mentionPartyMap);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<RoomListViewModel> GetList(MentionPartyMapFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var count = await query.CountAsync();

        var mentionPartyMaps = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new MentionPartyMapResultViewModel
            {
                Id = r.Id,
                MentionId = r.MentionId,
                PartyId = r.PartyId
            })
            .ToListAsync();

        return new MentionPartyMapResultViewModel
        {
            Count = count,
            ResultViewModels = mentionPartyMaps
        };
    }

    public async ValueTask Update(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();

        var mentionPartyMap = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (mentionPartyMap is not null)
        {
            mentionPartyMap.MentionId = viewModel.MentionId;
            room.PartyId = viewModel.PartyId;

            await _artemisDbContext.SaveChangesAsync();
        }
    }
    public async ValueTask Delete(int id)
    {
        var mentionPartyMap = await _artemisDbContext.MentionPartyMaps.FirstOrDefaultAsync(i => i.Id == id);
        if (mentionPartyMap is not null)
        {
            _artemisDbContext.MentionPartyMaps.Remove(mentionPartyMap);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}