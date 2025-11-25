using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class MessageService : IMessageService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public MessageService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateMessageViewModel viewModel)
    {
        var message = new Message()
        {
            RoomId = viewModel.RoomId,
            PartyId = viewModel.PartyId,
            Content = viewModel.Content,
            Upvote = viewModel.Upvote,
            Downvote = viewModel.Downvote,
            LastUpdateDate = viewModel.LastUpdateDate ?? DateTime.UtcNow
        };
        await _artemisDbContext.Messages.AddAsync(message);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<MessageListViewModel> GetList(MessageFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Messages.AsQueryable();
        var count = await query.CountAsync();

        if (filterViewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == filterViewModel.RoomId.Value);
        }

        if (filterViewModel.PartyId.HasValue)
        {
            query = query.Where(x => x.PartyId == filterViewModel.PartyId.Value);
        }

        var messages = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(m => new MessageResultViewModel
            {
                Id = m.Id,
                RoomId = m.RoomId,
                PartyId = m.PartyId,
                Content = m.Content,
                Upvote = m.Upvote,
                Downvote = m.Downvote,
                LastUpdateDate = m.LastUpdateDate,
                CreateDate = m.CreateDate
            })
            .ToListAsync();

        return new MessageListViewModel
        {
            Count = count,
            ResultViewmodels = messages
        };
    }

    public async ValueTask Update(CreateOrUpdateMessageViewModel viewModel)
    {
        if (!viewModel.Id.HasValue)
        {
            throw new ArgumentException("Id is required for update operation");
        }

        var query = _artemisDbContext.Messages.AsQueryable();
        var message = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id.Value);
        if (message is not null)
        {
            message.RoomId = viewModel.RoomId;
            message.PartyId = viewModel.PartyId;
            message.Content = viewModel.Content;
            message.Upvote = viewModel.Upvote;
            message.Downvote = viewModel.Downvote;
            message.LastUpdateDate = viewModel.LastUpdateDate ?? DateTime.UtcNow;

            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask Delete(int id)
    {
        var message = await _artemisDbContext.Messages.FirstOrDefaultAsync(i => i.Id == id);
        if (message is not null)
        {
            _artemisDbContext.Messages.Remove(message);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}

