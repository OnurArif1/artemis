namespace Artemis.API.Services.Interfaces;

public interface IRoomHashtagMapService
{
    ValueTask<RoomHashtagMapListViewModel> GetList(RoomHashtagMapFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateRoomHashtagMapViewModel viewModel);
    ValueTask Update(CreateOrUpdateRoomHashtagMapViewModel viewModel);
    ValueTask<ResultRoomHashtagMapLookupViewModel> GetLookup(GetLookupRoomHashtagMapViewModel viewModel);
    ValueTask Delete(int id);
}
