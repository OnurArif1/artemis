using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class RoomService : IRoomService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public RoomService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(Room room)
    {
        // todo ask. how to unique rooms?
        await _artemisDbContext.Rooms.AddAsync(room);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<IEnumerable<RoomGetViewModel>> GetList(RoomFilterViewModel filterViewModel)
    {
        var query = (from r in _artemisDbContext.Rooms
                     select new { r }).AsQueryable();

        var count = await query.CountAsync();
        query = query.OrderByDescending(i => i.r.CreateDate)
                     .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
                     .Take(filterViewModel.PageSize);

        var rooms = await (query.Select(rg => new RoomGetViewModel()
        {
            Id = rg.r.Id,
            Count = count
        })).AsNoTracking().ToListAsync();

        return rooms;
    }
}