using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class TopicService : ITopicService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public TopicService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateTopicViewModel viewModel)
    {
        var topic = new Topic()
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
            LastUpdateDate = DateTime.UtcNow
        };

        await _artemisDbContext.Topics.AddAsync(topic);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<TopicListViewModel> GetList(TopicFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Subscribes.AsQueryable();
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

    public async Task<TopicGetViewModel?> GetById(int id)
    {
        var query = _artemisDbContext.Subscribes.AsQueryable();
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

    public async ValueTask Update(CreateOrUpdateTopicViewModel viewModel)
    {
        var query = _artemisDbContext.Subscribes.AsQueryable();
        var topic = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (topic is not null)
        {
            topic.PartyId = viewModel.PartyId;
            topic.Title = viewModel.Title;
            topic.Type = viewModel.Type;
            topic.LocationX = viewModel.LocationX;
            topic.LocationY = viewModel.LocationY;
            topic.CategoryId = viewModel.CategoryId;
            topic.MentionId = viewModel.MentionId;
            topic.Upvote = viewModel.Upvote;
            topic.Downvote = viewModel.Downvote;
            topic.LastUpdateDate = DateTime.UtcNow;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask Delete(int id)
    {
        var topic = await _artemisDbContext.Topics.FirstOrDefaultAsync(i => i.Id == id);

        if (topic is not null)
        {
            _artemisDbContext.Topics.Remove(topic);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}