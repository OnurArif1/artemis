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

    public async ValueTask Create(Category category)
    {
        // todo ask. how to unique rooms?
        await _artemisDbContext.Categories.AddAsync(category);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<IEnumerable<CategoryGetViewModel>> GetList(CategoryFilterViewModel filterViewModel)
    {
        var query = (from r in _artemisDbContext.Categories
                     select new { r }).AsQueryable();

        var count = await query.CountAsync();
        query = query.OrderByDescending(i => i.r.CreateDate)
                     .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
                     .Take(filterViewModel.PageSize);

        var categories = await (query.Select(rg => new CategoryGetViewModel()
        {
            Id = rg.r.Id,
            Count = count
        })).AsNoTracking().ToListAsync();

        return categories;
    }

    public async ValueTask<int?> GetCategoryIdByName(string categoryName)
    {
        if (string.IsNullOrWhiteSpace(categoryName))
            return null;

        var id = await _artemisDbContext.Categories
            .AsNoTracking()
            .Where(c => c.Title == categoryName)
            .Select(c => (int?)c.Id)
            .FirstOrDefaultAsync();

        return id;
    }

    public async ValueTask<string?> GetCategoryNameById(int categoryId)
    {
        var name = await _artemisDbContext.Categories
            .AsNoTracking()
            .Where(c => c.Id == categoryId)
            .Select(c => c.Title)
            .FirstOrDefaultAsync();

        return name;
    }
}