using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class RoomService : IRoomService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public RoomService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateRoomViewModel viewModel)
    {
        // todo ask. how to unique rooms?
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
        await _artemisDbContext.Rooms.AddAsync(room);
        _artemisDbContext.SaveChanges();
    }

  public async ValueTask<RoomListViewModel> GetList(RoomFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var count = await query.CountAsync();

        var rooms = await query
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new RoomResultViewmodel
            {
                Id = r.Id,
                Title = r.Title,
                LocationX = r.LocationX,
                LocationY = r.LocationY,
                RoomType = r.RoomType,
                LifeCycle = r.LifeCycle,
                Upvote = r.Upvote,
                Downvote = r.Downvote,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new RoomListViewModel
        {
            Count = count,
            ResultViewmodels = rooms
        };
    }
}