using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class CommentService : ICommentService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IQueryable<Comment> query;

    public CommentService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.Comments.AsQueryable();
    }

    public async ValueTask<CommentListViewModel> GetList(CommentFilterViewModel filterViewModel)
    {
        IQueryable<Comment> baseQuery = query;

        if (filterViewModel.TopicId.HasValue && filterViewModel.TopicId.Value > 0)
        {
            baseQuery = baseQuery.Where(c => c.TopicId == filterViewModel.TopicId.Value);
        }

        var count = await baseQuery.CountAsync();

        var comments = await baseQuery
            .Include(c => c.Party)
            .OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new CommentResultViewModel
            {
                Id = r.Id,
                TopicId = r.TopicId,
                PartyId = r.PartyId,
                PartyName = r.Party != null ? r.Party.PartyName : null,
                Content = r.Content,
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

    public async ValueTask<CommentGetViewModel?> GetById(int id)
    {
        var comment = await query.Include(c => c.Party).FirstOrDefaultAsync(i => i.Id == id);

        if (comment is not null)
        {
            return new CommentGetViewModel
            {
                Id = comment.Id,
                TopicId = comment.TopicId,
                PartyId = comment.PartyId,
                PartyName = comment.Party != null ? comment.Party.PartyName : null,
                Content = comment.Content,
                Upvote = comment.Upvote,
                Downvote = comment.Downvote,
                LastUpdateDate = comment.LastUpdateDate,
                CreateDate = comment.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdateCommentViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.PartyId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "PartyId is required.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        if (viewModel.TopicId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "TopicId is required.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var now = DateTime.UtcNow;
        await _artemisDbContext.Comments.AddAsync(new Comment()
        {
            TopicId = viewModel.TopicId,
            PartyId = viewModel.PartyId,
            Content = viewModel.Content,
            Upvote = viewModel.Upvote,
            Downvote = viewModel.Downvote,
            LastUpdateDate = now,
            CreateDate = now
        });
        await _artemisDbContext.SaveChangesAsync();

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Update(CreateOrUpdateCommentViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id is required.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }
        
        var comment = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (comment is not null)
        {
            if (comment.TopicId != viewModel.TopicId)
                comment.TopicId = viewModel.TopicId;

            if (comment.PartyId != viewModel.PartyId)
                comment.PartyId = viewModel.PartyId;

            if (comment.Content != viewModel.Content)
                comment.Content = viewModel.Content;

            if (comment.Upvote != viewModel.Upvote)
                comment.Upvote = viewModel.Upvote;

            if (comment.Downvote != viewModel.Downvote)
                comment.Downvote = viewModel.Downvote;

            comment.LastUpdateDate = DateTime.UtcNow;
            await _artemisDbContext.SaveChangesAsync();
        }    

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Delete(int id)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id is required.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var comment = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (comment is not null)
        {
            _artemisDbContext.Comments.Remove(comment);
            await _artemisDbContext.SaveChangesAsync();
        }
        
        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}