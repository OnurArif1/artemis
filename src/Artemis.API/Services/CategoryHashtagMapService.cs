using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class CategoryHashtagMapService : ICategoryHashtagMapService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public CategoryHashtagMapService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateCategoryHashtagMapViewModel viewModel)
    {
        // Validate Category exists
        var categoryExists = await _artemisDbContext.Categories
            .AnyAsync(c => c.Id == viewModel.CategoryId);
        if (!categoryExists)
        {
            throw new InvalidOperationException($"Category with Id {viewModel.CategoryId} does not exist.");
        }

        // Validate Hashtag exists
        var hashtagExists = await _artemisDbContext.Hashtags
            .AnyAsync(h => h.Id == viewModel.HashtagId);
        if (!hashtagExists)
        {
            throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
        }

        var map = new CategoryHashtagMap()
        {
            CategoryId = viewModel.CategoryId,
            HashtagId = viewModel.HashtagId
        };
        await _artemisDbContext.CategoryHashtagMaps.AddAsync(map);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<CategoryHashtagMapListViewModel> GetList(CategoryHashtagMapFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.CategoryHashtagMaps.AsQueryable();
        var count = await query.CountAsync();

        if (filterViewModel.CategoryId.HasValue)
        {
            query = query.Where(x => x.CategoryId == filterViewModel.CategoryId.Value);
        }

        var maps = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new CategoryHashtagMapResultViewModel
            {
                Id = r.Id,
                CategoryId = r.CategoryId,
                HashtagId = r.HashtagId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new CategoryHashtagMapListViewModel
        {
            Count = count,
            ResultViewModels = maps
        };
    }

    public async ValueTask Update(CreateOrUpdateCategoryHashtagMapViewModel viewModel)
    {
        var map = await _artemisDbContext.CategoryHashtagMaps
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (map is not null)
        {
            // Validate Category exists
            var categoryExists = await _artemisDbContext.Categories
                .AnyAsync(c => c.Id == viewModel.CategoryId);
            if (!categoryExists)
            {
                throw new InvalidOperationException($"Category with Id {viewModel.CategoryId} does not exist.");
            }

            // Validate Hashtag exists
            var hashtagExists = await _artemisDbContext.Hashtags
                .AnyAsync(h => h.Id == viewModel.HashtagId);
            if (!hashtagExists)
            {
                throw new InvalidOperationException($"Hashtag with Id {viewModel.HashtagId} does not exist.");
            }

            map.CategoryId = viewModel.CategoryId;
            map.HashtagId = viewModel.HashtagId;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultCategoryHashtagMapLookupViewModel> GetLookup(GetLookupCategoryHashtagMapViewModel viewModel)
    {
        var query = _artemisDbContext.CategoryHashtagMaps.AsQueryable();

        if (viewModel.CategoryId.HasValue)
        {
            query = query.Where(x => x.CategoryId == viewModel.CategoryId.Value);
        }

        if (viewModel.HashtagId.HasValue)
        {
            query = query.Where(x => x.HashtagId == viewModel.HashtagId.Value);
        }

        var maps = await query
            .OrderBy(x => x.Id)
            .Take(50)
            .Select(p => new CategoryHashtagMapLookupViewModel
            {
                Id = p.Id,
                CategoryId = p.CategoryId,
                HashtagId = p.HashtagId
            })
            .ToListAsync();

        return new ResultCategoryHashtagMapLookupViewModel
        {
            Count = maps.Count(),
            ViewModels = maps
        };
    }

    public async ValueTask Delete(int id)
    {
        var map = await _artemisDbContext.CategoryHashtagMaps
            .FirstOrDefaultAsync(i => i.Id == id);
        if (map is not null)
        {
            _artemisDbContext.CategoryHashtagMaps.Remove(map);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}

