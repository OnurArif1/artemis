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

    public async ValueTask<ResultTopicLookupViewModel> GetTopicLookup(GetLookupTopicViewModel viewModel)
    {
        var query = _artemisDbContext.Topics.AsQueryable();

        if (!string.IsNullOrWhiteSpace(viewModel.SearchText))
        {
            query = query.Where(x => x.Title.Contains(viewModel.SearchText));
        }

        if (viewModel.TopicId.HasValue)
        {
            query = query.Where(x => x.Id == viewModel.TopicId.Value);
        }

        var topics = await query
            .OrderBy(x => x.Title)
            .Take(50)
            .Select(t => new TopicLookupViewModel
            {
                TopicId = t.Id,
                Title = t.Title
            })
            .ToListAsync();

        return new ResultTopicLookupViewModel
        {
            Count = topics.Count,
            ViewModels = topics
        };
    }
}

