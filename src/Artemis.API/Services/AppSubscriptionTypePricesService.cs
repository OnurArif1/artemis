using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class AppSubscriptionTypePricesService : IAppSubscriptionTypePricesService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public AppSubscriptionTypePricesService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel)
    {
        var appSubscriptionTypePrices = new AppSubscriptionTypePrices
        {
            SubscriptionType = viewModel.SubscriptionType,
            Price = viewModel.Price,
            PriceCurrencyType = viewModel.PriceCurrencyType,
            AppSubscriptionPeriodType = viewModel.AppSubscriptionPeriodType,
            ThruDate = null
        };
        
        await _artemisDbContext.AppSubscriptionTypePrices.AddAsync(appSubscriptionTypePrices);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<AppSubscriptionTypePricesListViewModel> GetList(AppSubscriptionTypePricesFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.AppSubscriptionTypePrices.AsQueryable();
        
        if (filterViewModel.SubscriptionType.HasValue)
        {
            query = query.Where(x => x.SubscriptionType == filterViewModel.SubscriptionType.Value);
        }
        
        if (filterViewModel.PriceCurrencyType.HasValue)
        {
            query = query.Where(x => x.PriceCurrencyType == filterViewModel.PriceCurrencyType.Value);
        }
        
        var count = await query.CountAsync();

        var appSubscriptionTypePrices = await query
            .OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new AppSubscriptionTypePricesResultViewModel
            {
                Id = r.Id,
                SubscriptionType = r.SubscriptionType,
                Price = r.Price,
                PriceCurrencyType = r.PriceCurrencyType,
                AppSubscriptionPeriodType = r.AppSubscriptionPeriodType,
                CreateDate = r.CreateDate,
                ThruDate = r.ThruDate
            })
            .AsNoTracking()
            .ToListAsync();

        return new AppSubscriptionTypePricesListViewModel
        {
            Count = count,
            ResultViewmodels = appSubscriptionTypePrices
        };
    }

    public async ValueTask Update(CreateOrUpdateAppSubscriptionTypePricesViewModel viewModel)
    {
        if (!viewModel.Id.HasValue)
        {
            throw new ArgumentException("Id is required for update.");
        }

        var appSubscriptionTypePrices = await _artemisDbContext.AppSubscriptionTypePrices
            .FirstOrDefaultAsync(i => i.Id == viewModel.Id.Value);
            
        if (appSubscriptionTypePrices is not null)
        {
            appSubscriptionTypePrices.SubscriptionType = viewModel.SubscriptionType;
            appSubscriptionTypePrices.Price = viewModel.Price;
            appSubscriptionTypePrices.PriceCurrencyType = viewModel.PriceCurrencyType;
            appSubscriptionTypePrices.AppSubscriptionPeriodType = viewModel.AppSubscriptionPeriodType;
            
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask Delete(int id)
    {
        var appSubscriptionTypePrices = await _artemisDbContext.AppSubscriptionTypePrices
            .FirstOrDefaultAsync(i => i.Id == id);
            
        if (appSubscriptionTypePrices is not null)
        {
            var todayUtc = DateTime.UtcNow.Date;
            appSubscriptionTypePrices.ThruDate = todayUtc;
            
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}
