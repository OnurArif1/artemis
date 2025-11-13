using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class MentionService : IMentionService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public MentionService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateMentionViewModel viewModel)
    {
        // Normalize 0 or negative values to null
        var roomId = viewModel.RoomId.HasValue && viewModel.RoomId.Value > 0 ? viewModel.RoomId : null;
        var messageId = viewModel.MessageId.HasValue && viewModel.MessageId.Value > 0 ? viewModel.MessageId : null;
        var commentId = viewModel.CommentId.HasValue && viewModel.CommentId.Value > 0 ? viewModel.CommentId : null;
        var topicId = viewModel.TopicId.HasValue && viewModel.TopicId.Value > 0 ? viewModel.TopicId : null;

        var mention = new Mention()
        {
            RoomId = roomId,
            MessageId = messageId,
            CommentId = commentId,
            TopicId = topicId
        };
        
        await _artemisDbContext.Mentions.AddAsync(mention);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<MentionListViewModel> GetList(MentionFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Mentions.AsQueryable();
        var count = await query.CountAsync();

        if (filterViewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == filterViewModel.RoomId.Value);
        }

        if (filterViewModel.MessageId.HasValue)
        {
            query = query.Where(x => x.MessageId == filterViewModel.MessageId.Value);
        }

        if (filterViewModel.CommentId.HasValue)
        {
            query = query.Where(x => x.CommentId == filterViewModel.CommentId.Value);
        }

        if (filterViewModel.TopicId.HasValue)
        {
            query = query.Where(x => x.TopicId == filterViewModel.TopicId.Value);
        }

        var mentions = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new MentionResultViewModel
            {
                Id = r.Id,
                RoomId = r.RoomId,
                MessageId = r.MessageId,
                CommentId = r.CommentId,
                TopicId = r.TopicId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new MentionListViewModel
        {
            Count = count,
            ResultViewModels = mentions
        };
    }

    public async ValueTask Update(CreateOrUpdateMentionViewModel viewModel)
    {
        var mention = await _artemisDbContext.Mentions
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (mention is not null)
        {
            // Normalize 0 or negative values to null
            var roomId = viewModel.RoomId.HasValue && viewModel.RoomId.Value > 0 ? viewModel.RoomId : null;
            var messageId = viewModel.MessageId.HasValue && viewModel.MessageId.Value > 0 ? viewModel.MessageId : null;
            var commentId = viewModel.CommentId.HasValue && viewModel.CommentId.Value > 0 ? viewModel.CommentId : null;
            var topicId = viewModel.TopicId.HasValue && viewModel.TopicId.Value > 0 ? viewModel.TopicId : null;

            mention.RoomId = roomId;
            mention.MessageId = messageId;
            mention.CommentId = commentId;
            mention.TopicId = topicId;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultMentionLookupViewModel> GetLookup(GetLookupMentionViewModel viewModel)
    {
        var query = _artemisDbContext.Mentions.AsQueryable();

        if (viewModel.RoomId.HasValue)
        {
            query = query.Where(x => x.RoomId == viewModel.RoomId.Value);
        }

        if (viewModel.MessageId.HasValue)
        {
            query = query.Where(x => x.MessageId == viewModel.MessageId.Value);
        }

        if (viewModel.CommentId.HasValue)
        {
            query = query.Where(x => x.CommentId == viewModel.CommentId.Value);
        }

        if (viewModel.TopicId.HasValue)
        {
            query = query.Where(x => x.TopicId == viewModel.TopicId.Value);
        }

        var mentions = await query
            .OrderBy(x => x.Id)
            .Take(50)
            .Select(p => new MentionLookupViewModel
            {
                Id = p.Id,
                RoomId = p.RoomId,
                MessageId = p.MessageId,
                CommentId = p.CommentId,
                TopicId = p.TopicId
            })
            .ToListAsync();

        return new ResultMentionLookupViewModel
        {
            Count = mentions.Count(),
            ViewModels = mentions
        };
    }

    public async ValueTask Delete(int id)
    {
        var mention = await _artemisDbContext.Mentions
            .FirstOrDefaultAsync(i => i.Id == id);
        if (mention is not null)
        {
            _artemisDbContext.Mentions.Remove(mention);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}

