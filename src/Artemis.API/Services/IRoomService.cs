using Artemis.API.Entities;

namespace Artemis.API.Services;

public interface IRoomService
{
    ValueTask<IEnumerable<RoomGetViewModel>> GetList(RoomFilterViewModel filterViewModel);
    ValueTask Create(Room room);
}