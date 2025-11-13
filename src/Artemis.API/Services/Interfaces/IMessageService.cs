namespace Artemis.API.Services.Interfaces;

public interface IMessageService
{
    ValueTask<MessageListViewModel> GetList(MessageFilterViewModel filterViewModel);
    ValueTask Create(CreateOrUpdateMessageViewModel viewModel);
    ValueTask Update(CreateOrUpdateMessageViewModel viewModel);
    ValueTask Delete(int id);
}

