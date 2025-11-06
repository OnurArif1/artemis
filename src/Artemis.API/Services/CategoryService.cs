using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class CategoryService : ICategoryService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public CategoryService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateCategoryViewModel viewModel)
    {
        var category = new Category
        {
            Title = viewModel.Title,
            CreateDate = viewModel.CreateDate
        };
        await _artemisDbContext.Categories.AddAsync(category);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<CategoryListViewModel> GetList(CategoryFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Categories.AsQueryable();
        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            query = query.Where(x => x.Title.Contains(filterViewModel.Title));
        }
        var count = await query.CountAsync();

        var categories = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new CategoryResultViewModel
            {
                Id = r.Id,
                Title = r.Title,
                CreateDate = r.CreateDate
            })
            .AsNoTracking()
            .ToListAsync();

        return new CategoryListViewModel
        {
            Count = count,
            ResultViewmodels = categories
        };
    }

    public async ValueTask Update(CreateOrUpdateCategoryViewModel viewModel)
    {
        var category = await _artemisDbContext.Categories
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (category is not null)
        {
            category.Title = viewModel.Title;
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<ResultCategoryLookupViewModel> GetCategoryLookup(GetLookupCategoryViewModel viewModel)
    {
        var query = _artemisDbContext.Categories.AsQueryable();

        if (!string.IsNullOrWhiteSpace(viewModel.SearchText))
        {
            query = query.Where(x => x.Title.Contains(viewModel.SearchText));
        }

        if (viewModel.CategoryId.HasValue)
        {
            query = query.Where(x => x.Id == viewModel.CategoryId.Value);
        }

        var categories = await query
            .OrderBy(x => x.Title)
            .Take(50)
            .Select(c => new CategoryLookupViewModel
            {
                CategoryId = c.Id,
                Title = c.Title
            })
            .ToListAsync();

        return new ResultCategoryLookupViewModel
        {
            Count = categories.Count,
            ViewModels = categories
        };
    }

    public async ValueTask Delete(int id)
    {
        var category = await _artemisDbContext.Categories
            .FirstOrDefaultAsync(i => i.Id == id);
        if (category is not null)
        {
            _artemisDbContext.Categories.Remove(category);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}