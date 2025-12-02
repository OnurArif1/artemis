using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Artemis.API.ViewModels;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class RoomService : IRoomService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public RoomService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateRoomViewModel viewModel)
    {
        var room = new Room()
        {
            TopicId = viewModel.TopicId,
            PartyId = viewModel.PartyId,
            CategoryId = viewModel.CategoryId,
            Title = viewModel.Title,
            LocationX = viewModel.LocationX,
            LocationY = viewModel.LocationY,
            RoomType = viewModel.RoomType,
            LifeCycle = viewModel.LifeCycle,
            ChannelId = viewModel.ChannelId,
            ReferenceId = viewModel.ReferenceId,
            Upvote = viewModel.Upvote,
            Downvote = viewModel.Downvote
        };

        if (viewModel.PartyId > 0)
        {
            var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId);  
            ((List<Party>)room.Parties).Add(party);
        }
              
        await _artemisDbContext.Rooms.AddAsync(room);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask AddParty(AddPartyToRoomViewModel viewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var room = await query.FirstOrDefaultAsync(i => i.Id == viewModel.RoomId);
        if (room is not null)
        {
            var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId);  
            ((List<Party>)room.Parties).Add(party);
            await  _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<RoomListViewModel> GetList(RoomFilterViewModel filterViewModel)
    {
        var baseQuery = _artemisDbContext.Rooms.AsQueryable();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            baseQuery = baseQuery.Where(x => x.Title.Contains(filterViewModel.Title));
        }

        var count = await baseQuery.CountAsync();

        var query = baseQuery.Include(r => r.Parties).Include(r => r.Category);

        var rooms = await query
            .OrderByDescending(r => r.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .AsSplitQuery() 
            .ToListAsync();  

        var roomViewModels = rooms.Select(r => new RoomResultViewModel
        {
            Id = r.Id,
            Title = r.Title,
            LocationX = r.LocationX,
            LocationY = r.LocationY,
            RoomType = r.RoomType,
            LifeCycle = r.LifeCycle,
            ChannelId = r.ChannelId,
            Upvote = r.Upvote,
            Downvote = r.Downvote,
            CreateDate = r.CreateDate,
            PartyId = r.PartyId,
            PartyName = r.Parties.FirstOrDefault(i => i.Id == r.PartyId)?.PartyName,
            Parties = r.Parties.Select(p => new PartyInfo
            {
                Id = p.Id,
                PartyName = p.PartyName
            }).ToList(),
            CategoryTitle = r.Category?.Title
        }).ToList();

        return new RoomListViewModel
        {
            Count = count,
            ResultViewModels = roomViewModels
        };
    }

    public async ValueTask Update(CreateOrUpdateRoomViewModel viewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var room = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (room is not null)
        {
            room.TopicId = viewModel.TopicId;
            room.PartyId = viewModel.PartyId;
            room.CategoryId = viewModel.CategoryId;
            room.Title = viewModel.Title;
            room.LocationX = viewModel.LocationX;
            room.LocationY = viewModel.LocationY;
            room.RoomType = viewModel.RoomType;
            room.LifeCycle = viewModel.LifeCycle;
            room.ChannelId = viewModel.ChannelId;
            room.ReferenceId = viewModel.ReferenceId;
            room.Upvote = viewModel.Upvote;
            room.Downvote = viewModel.Downvote;

            if (viewModel.PartyId > 0)
            {
                var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId);  
                ((List<Party>)room.Parties).Add(party);
            }

            await _artemisDbContext.SaveChangesAsync();
        }
    }
    public async ValueTask Delete(int id)
    {
        var room = await _artemisDbContext.Rooms.FirstOrDefaultAsync(i => i.Id == id);
        if (room is not null)
        {
            _artemisDbContext.Rooms.Remove(room);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}