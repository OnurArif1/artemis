using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class TopicHashtagMapService : ITopicHashtagMapService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public TopicHashtagMapService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateTopicHashtagMapViewModel viewModel)
    {
        var topicExists = await _artemisDbContext.Topics
            .AnyAsync(t => t.Id == viewModel.TopicId);
        if (!topicExists)
        {
            throw new InvalidOperationException($"Topic with Id {viewModel.TopicId} does not exist.");
        }

        var hashtagExists = await _artemisDbContext.Hashtags
            .AnyAsync(h => h.Id == viewModel.HashtagId);
        if (!hashtagExists)
        {
            throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
        }

        var map = new TopicHashtagMap()
        {
            TopicId = viewModel.TopicId,
            HashtagId = viewModel.HashtagId
        };
        await _artemisDbContext.TopicHashtagMaps.AddAsync(map);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<TopicHashtagMapListViewModel> GetList(TopicHashtagMapFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.TopicHashtagMaps.AsQueryable();
        var count = await query.CountAsync();

        if (filterViewModel.TopicId.HasValue)
        {
            query = query.Where(x => x.TopicId == filterViewModel.TopicId.Value);
        }

        var maps = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new TopicHashtagMapResultViewModel
            {
                Id = r.Id,
                TopicId = r.TopicId,
                HashtagId = r.HashtagId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new TopicHashtagMapListViewModel
        {
            Count = count,
            ResultViewModels = maps
        };
    }

    public async ValueTask Update(CreateOrUpdateTopicHashtagMapViewModel viewModel)
    {
        var map = await _artemisDbContext.TopicHashtagMaps
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (map is not null)
        {
            var topicExists = await _artemisDbContext.Topics
                .AnyAsync(t => t.Id == viewModel.TopicId);
            if (!topicExists)
            {
                throw new InvalidOperationException($"Topic with Id {viewModel.TopicId} does not exist.");
            }

            var hashtagExists = await _artemisDbContext.Hashtags
                .AnyAsync(h => h.Id == viewModel.HashtagId);
            if (!hashtagExists)
            {
                throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
            }

            map.TopicId = viewModel.TopicId;
            map.HashtagId = viewModel.HashtagId;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultTopicHashtagMapLookupViewModel> GetLookup(GetLookupTopicHashtagMapViewModel viewModel)
    {
        var query = _artemisDbContext.TopicHashtagMaps.AsQueryable();

        if (viewModel.TopicId.HasValue)
        {
            query = query.Where(x => x.TopicId == viewModel.TopicId.Value);
        }

        if (viewModel.HashtagId.HasValue)
        {
            query = query.Where(x => x.HashtagId == viewModel.HashtagId.Value);
        }

        var maps = await query
            .OrderBy(x => x.Id)
            .Take(50)
            .Select(p => new TopicHashtagMapLookupViewModel
            {
                Id = p.Id,
                TopicId = p.TopicId,
                HashtagId = p.HashtagId
            })
            .ToListAsync();

        return new ResultTopicHashtagMapLookupViewModel
        {
            Count = maps.Count(),
            ViewModels = maps
        };
    }

    public async ValueTask Delete(int id)
    {
        var map = await _artemisDbContext.TopicHashtagMaps
            .FirstOrDefaultAsync(i => i.Id == id);
        if (map is not null)
        {
            _artemisDbContext.TopicHashtagMaps.Remove(map);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}

