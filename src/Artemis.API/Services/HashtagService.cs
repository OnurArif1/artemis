using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class HashtagService : IHashtagService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public HashtagService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateHashtagViewModel viewModel)
    {
        var hashtag = new Hashtag()
        {
            HashtagName = viewModel.HashtagName
        };

        await _artemisDbContext.Hashtags.AddAsync(hashtag);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<HashtagListViewModel> GetList(HashtagFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Hashtags.AsQueryable();
        var count = await query.CountAsync();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            query = query.Where(x => x.HashtagName.Contains(filterViewModel.Title));
        }

        var hashtags = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new HashtagResultViewModel
            {
                Id = r.Id,
                HashtagName = r.HashtagName,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new HashtagListViewModel
        {
            Count = count,
            ResultViewmodels = hashtags
        };
    }

    public async ValueTask Update(CreateOrUpdateHashtagViewModel viewModel)
    {
        var hashtag = await _artemisDbContext.Hashtags
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (hashtag is not null)
        {
            hashtag.HashtagName = viewModel.HashtagName;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultHashtagLookupViewModel> GetHashtagLookup(GetLookupHashtagViewModel viewModel)
    {
        var query = _artemisDbContext.Hashtags.AsQueryable();

        if (!string.IsNullOrWhiteSpace(viewModel.SearchText))
        {
            query = query.Where(x =>
                x.HashtagName.Contains(viewModel.SearchText) ||
                x.Id.ToString().Contains(viewModel.SearchText)
            );
        }

        if (viewModel.HashtagId.HasValue)
        {
            query = query.Where(x => x.Id == viewModel.HashtagId.Value);
        }

        var hashtags = await query
            .OrderBy(x => x.HashtagName)
            .Take(50)
            .Select(p => new HashtagLookupViewModel
            {
                HashtagId = p.Id,
                HashtagName = p.HashtagName
            })
            .ToListAsync();

        return new ResultHashtagLookupViewModel
        {
            Count = hashtags.Count,
            ViewModels = hashtags
        };
    }

    public async ValueTask Delete(int id)
    {
        var hashtag = await _artemisDbContext.Hashtags
            .FirstOrDefaultAsync(i => i.Id == id);

        if (hashtag is not null)
        {
            _artemisDbContext.Hashtags.Remove(hashtag);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}
