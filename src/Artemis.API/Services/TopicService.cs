using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class TopicService : ITopicService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IQueryable<Topic> query;

    public TopicService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.Topics.AsQueryable();
    }

    public async ValueTask<TopicListViewModel> GetList(TopicFilterViewModel filterViewModel)
    {
        var count = await query.CountAsync();

        var topics = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new TopicResultViewModel
            {
                Id = r.Id,
                PartyId = r.PartyId,
                Type = r.Type,
                LocationX = r.LocationX,
                LocationY = r.LocationY,
                CategoryId = r.CategoryId,
                MentionId = r.MentionId,
                Upvote = r.Upvote,
                Downvote = r.Downvote,
                LastUpdateDate = r.LastUpdateDate,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new TopicListViewModel
        {
            Count = count,
            ResultViewModels = topics
        };
    }

    public async ValueTask<TopicGetViewModel?> GetById(int id)
    {
        var topic = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (topic is not null)
        {
            return new TopicGetViewModel
            {
                Id = topic.Id,
                PartyId = topic.PartyId,
                Title = topic.Title,
                Type = topic.Type,
                LocationX = topic.LocationX,
                LocationY = topic.LocationY,
                CategoryId = topic.CategoryId,
                MentionId = topic.MentionId,
                Upvote = topic.Upvote,
                Downvote = topic.Downvote,
                LastUpdateDate = topic.LastUpdateDate,
                CreateDate = topic.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdateTopicViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.PartyId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "PartyId must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        if (string.IsNullOrWhiteSpace(viewModel.Title))
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Title cannot be null or whitespace.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.NullOrWhiteSpace;

            return resultViewModel;
        }

        await _artemisDbContext.Topics.AddAsync(new Topic
        {
            PartyId = viewModel.PartyId,
            Title = viewModel.Title,
            Type = viewModel.Type,
            LocationX = viewModel.LocationX,
            LocationY = viewModel.LocationY,
            CategoryId = viewModel.CategoryId,
            MentionId = viewModel.MentionId,
            Upvote = viewModel.Upvote,
            Downvote = viewModel.Downvote,
            LastUpdateDate = DateTime.UtcNow,
            CreateDate = DateTime.UtcNow
        });
        _artemisDbContext.SaveChanges();

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Update(CreateOrUpdateTopicViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var topic = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (topic is not null)
        {
            if (topic.PartyId != viewModel.PartyId)
                topic.PartyId = viewModel.PartyId;

            if (topic.Title != viewModel.Title)
                topic.Title = viewModel.Title;
            
            if (topic.Type != viewModel.Type)
                topic.Type = viewModel.Type;

            if (topic.LocationX != viewModel.LocationX)
                topic.LocationX = viewModel.LocationX;

            if (topic.LocationY != viewModel.LocationY)
                topic.LocationY = viewModel.LocationY;

            if (topic.CategoryId != viewModel.CategoryId)
                topic.CategoryId = viewModel.CategoryId;

            if (topic.MentionId != viewModel.MentionId)
                topic.MentionId = viewModel.MentionId;

            if (topic.Upvote != viewModel.Upvote)
                topic.Upvote = viewModel.Upvote;

            if (topic.Downvote != viewModel.Downvote)
                topic.Downvote = viewModel.Downvote;

            topic.LastUpdateDate = DateTime.UtcNow;
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
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var topic = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (topic is not null)
        {
            _artemisDbContext.Topics.Remove(topic);
            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}