using Artemis.API.Entities;

namespace Artemis.API.Services.Interfaces;

public interface IRoomService
{
    ValueTask<RoomListViewModel> GetList(RoomFilterViewModel filterViewModel);
    ValueTask Create(CreateRoomViewModel viewModel);
}