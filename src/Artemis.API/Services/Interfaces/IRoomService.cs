using Artemis.API.ViewModels;

namespace Artemis.API.Services.Interfaces;

public interface IRoomService
{
    ValueTask<RoomListViewModel> GetList(RoomFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateRoomViewModel viewModel);
    ValueTask Update(CreateOrUpdateRoomViewModel viewModel);
    ValueTask UpdateUpvote(int roomId, int upvote);
    ValueTask Delete(int id);
    ValueTask AddParty(AddPartyToRoomViewModel viewModel);
}