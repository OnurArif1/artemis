using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Artemis.API.Utilities;
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
        if (viewModel.RoomId > 0)
        {
            var room = await _artemisDbContext.Rooms
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.Id == viewModel.RoomId);
            if (room is null)
            {
                throw new InvalidOperationException("Oda bulunamadı.");
            }

            if (RoomLifecycleHelper.IsExpired(room))
            {
                throw new InvalidOperationException("Bu oda artık aktif değil; mesaj gönderilemez.");
            }
        }

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

        if (viewModel.MentionedPartyIds != null)
        {
            int? topicId = null;
            if (viewModel.RoomId > 0)
            {
                var room = await _artemisDbContext.Rooms
                    .AsNoTracking()
                    .FirstOrDefaultAsync(r => r.Id == viewModel.RoomId);
                if (room != null)
                {
                    topicId = room.TopicId;
                }
            }

            var mention = new Mention()
            {
                RoomId = viewModel.RoomId,
                MessageId = message.Id,
                TopicId = topicId
            };
            await _artemisDbContext.Mentions.AddAsync(mention);
            await _artemisDbContext.SaveChangesAsync();

            foreach (var mentionedPartyId in viewModel.MentionedPartyIds)
            {
                if (mentionedPartyId > 0)
                {
                    var mentionPartyMap = new MentionPartyMap()
                    {
                        MentionId = mention.Id,
                        PartyId = mentionedPartyId
                    };
                    await _artemisDbContext.MentionPartyMaps.AddAsync(mentionPartyMap);
                }
            }
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<MessageListViewModel> GetList(MessageFilterViewModel filterViewModel)
    {
        if (filterViewModel.LatestInRoomsWhereParticipated &&
            filterViewModel.ParticipatingPartyId.HasValue &&
            filterViewModel.ParticipatingPartyId.Value > 0)
        {
            return await GetLatestMessagePerRoomWherePartyParticipated(
                filterViewModel.ParticipatingPartyId.Value);
        }

        var query = _artemisDbContext.Messages.AsQueryable();

        if (filterViewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == filterViewModel.RoomId.Value);
        }

        if (filterViewModel.PartyId.HasValue)
        {
            query = query.Where(x => x.PartyId == filterViewModel.PartyId.Value);
        }

        var count = await query.CountAsync();

        var messages = await query
            .OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(m => new MessageResultViewModel
            {
                Id = m.Id,
                RoomId = m.RoomId,
                PartyId = m.PartyId,
                PartyName = m.Party != null ? m.Party.PartyName : null,
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

    /// <summary>
    /// Kullanıcının mesaj yazdığı odalar için odadaki (herhangi birinden) en son mesajı döndürür.
    /// </summary>
    private async ValueTask<MessageListViewModel> GetLatestMessagePerRoomWherePartyParticipated(int participantPartyId)
    {
        var roomIds = await _artemisDbContext.Messages.AsNoTracking()
            .Where(m => m.PartyId == participantPartyId)
            .Select(m => m.RoomId)
            .Distinct()
            .ToListAsync();

        if (roomIds.Count == 0)
        {
            return new MessageListViewModel { Count = 0, ResultViewmodels = [] };
        }

        var latestIds = await _artemisDbContext.Messages
            .Where(m => roomIds.Contains(m.RoomId))
            .GroupBy(m => m.RoomId)
            .Select(g => g.OrderByDescending(x => x.CreateDate).ThenByDescending(x => x.Id).First().Id)
            .ToListAsync();

        var messages = await _artemisDbContext.Messages
            .Where(m => latestIds.Contains(m.Id))
            .OrderByDescending(m => m.CreateDate)
            .Select(m => new MessageResultViewModel
            {
                Id = m.Id,
                RoomId = m.RoomId,
                PartyId = m.PartyId,
                PartyName = m.Party != null ? m.Party.PartyName : null,
                Content = m.Content,
                Upvote = m.Upvote,
                Downvote = m.Downvote,
                LastUpdateDate = m.LastUpdateDate,
                CreateDate = m.CreateDate
            })
            .ToListAsync();

        return new MessageListViewModel
        {
            Count = messages.Count,
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

