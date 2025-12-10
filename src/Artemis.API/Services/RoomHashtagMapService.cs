using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class RoomHashtagMapService : IRoomHashtagMapService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public RoomHashtagMapService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateRoomHashtagMapViewModel viewModel)
    {
        var roomExists = await _artemisDbContext.Rooms
            .AnyAsync(r => r.Id == viewModel.RoomId);
        if (!roomExists)
        {
            throw new InvalidOperationException($"Room with Id {viewModel.RoomId} does not exist.");
        }

        var hashtagExists = await _artemisDbContext.Hashtags
            .AnyAsync(h => h.Id == viewModel.HashtagId);
        if (!hashtagExists)
        {
            throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
        }

        var existingMap = await _artemisDbContext.RoomHashtags
            .AnyAsync(m => m.RoomId == viewModel.RoomId && m.HashtagId == viewModel.HashtagId);
        if (existingMap)
        {
            throw new InvalidOperationException($"Room with Id {viewModel.RoomId} already has hashtag with Id {viewModel.HashtagId}.");
        }

        var map = new RoomHashtagMap()
        {
            RoomId = viewModel.RoomId,
            HashtagId = viewModel.HashtagId
        };
        await _artemisDbContext.RoomHashtags.AddAsync(map);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<RoomHashtagMapListViewModel> GetList(RoomHashtagMapFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.RoomHashtags.AsQueryable();

        if (filterViewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == filterViewModel.RoomId.Value);
        }

        var count = await query.CountAsync();

        var maps = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new RoomHashtagMapResultViewModel
            {
                Id = r.Id,
                RoomId = r.RoomId,
                HashtagId = r.HashtagId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new RoomHashtagMapListViewModel
        {
            Count = count,
            ResultViewModels = maps
        };
    }

    public async ValueTask Update(CreateOrUpdateRoomHashtagMapViewModel viewModel)
    {
        var map = await _artemisDbContext.RoomHashtags
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (map is not null)
        {
            var roomExists = await _artemisDbContext.Rooms
                .AnyAsync(r => r.Id == viewModel.RoomId);
            if (!roomExists)
            {
                throw new InvalidOperationException($"Room with Id {viewModel.RoomId} does not exist.");
            }

            var hashtagExists = await _artemisDbContext.Hashtags
                .AnyAsync(h => h.Id == viewModel.HashtagId);
            if (!hashtagExists)
            {
                throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
            }

            var existingMap = await _artemisDbContext.RoomHashtags
                .AnyAsync(m => m.RoomId == viewModel.RoomId && m.HashtagId == viewModel.HashtagId && m.Id != viewModel.Id);
            if (existingMap)
            {
                throw new InvalidOperationException($"Room with Id {viewModel.RoomId} already has hashtag with Id {viewModel.HashtagId}.");
            }

            map.RoomId = viewModel.RoomId;
            map.HashtagId = viewModel.HashtagId;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultRoomHashtagMapLookupViewModel> GetLookup(GetLookupRoomHashtagMapViewModel viewModel)
    {
        var query = _artemisDbContext.RoomHashtags.AsQueryable();

        if (viewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == viewModel.RoomId.Value);
        }

        if (viewModel.HashtagId.HasValue)
        {
            query = query.Where(x => x.HashtagId == viewModel.HashtagId.Value);
        }

        var maps = await query
            .OrderBy(x => x.Id)
            .Take(50)
            .Select(p => new RoomHashtagMapLookupViewModel
            {
                Id = p.Id,
                RoomId = p.RoomId,
                HashtagId = p.HashtagId
            })
            .ToListAsync();

        return new ResultRoomHashtagMapLookupViewModel
        {
            Count = maps.Count(),
            ViewModels = maps
        };
    }

    public async ValueTask Delete(int id)
    {
        var map = await _artemisDbContext.RoomHashtags
            .FirstOrDefaultAsync(i => i.Id == id);
        if (map is not null)
        {
            _artemisDbContext.RoomHashtags.Remove(map);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}
