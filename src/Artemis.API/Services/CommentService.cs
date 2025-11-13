using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class CommentService : ICommentService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public CommentService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateCommentViewModel viewModel)
    {
        await _artemisDbContext.Comments.AddAsync(new Comment()
        {
            TopicId = viewModel.TopicId,
            PartyId = viewModel.PartyId,
            Upvote = viewModel.Upvote,
            Downvote = viewModel.Downvote,
            LastUpdateDate = DateTime.UtcNow
        });
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<TopicListViewModel> GetList(CommentFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Comments.AsQueryable();
        var count = await query.CountAsync();

        var comments = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new CommentResultViewModel
            {
                Id = r.Id,
                TopicId = r.TopicId,
                PartyId = r.PartyId
                Upvote = r.Upvote,
                Downvote = r.Downvote,
                LastUpdateDate = r.LastUpdateDate,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new CommentListViewModel
        {
            Count = count,
            ResultViewModels = comments
        };
    }

    public async Task<CommentGetViewModel?> GetById(int id)
    {
        var query = _artemisDbContext.Comments.AsQueryable();
        var comment = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (comment is not null)
        {
            return new CommentGetViewModel
            {
                Id = topic.Id,
                TopicId = topic.TopicId,
                PartyId = topic.PartyId,
                Upvote = topic.Upvote,
                Downvote = topic.Downvote,
                LastUpdateDate = topic.LastUpdateDate,
                CreateDate = topic.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask Update(CreateOrUpdateCommentViewModel viewModel)
    {
        var query = _artemisDbContext.Comments.AsQueryable();
        var comment = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (comment is not null)
        {
            comment.TopicId = viewModel.TopicId;
            comment.PartyId = viewModel.PartyId;
            comment.Upvote = viewModel.Upvote;
            comment.Downvote = viewModel.Downvote;
            comment.LastUpdateDate = DateTime.UtcNow;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask Delete(int id)
    {
        var comment = await _artemisDbContext.Comments.FirstOrDefaultAsync(i => i.Id == id);

        if (comment is not null)
        {
            _artemisDbContext.Comments.Remove(comment);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}