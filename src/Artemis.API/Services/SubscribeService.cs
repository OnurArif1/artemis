using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class SubscribeService : ISubscribeService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IQueryable<Subscribe> query;

    public SubscribeService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.Subscribes.AsQueryable();
    }

    public async ValueTask<SubscribeListViewModel> GetList(SubscribeFilterViewModel filterViewModel)
    {
        var count = await query.CountAsync();

        var subscribes = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new SubscribeResultViewModel
            {
                Id = r.Id,
                CreatedPartyId = r.CreatedPartyId,
                SubscriberPartyId = r.SubscriberPartyId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new SubscribeListViewModel
        {
            Count = count,
            ResultViewModels = subscribes
        };
    }

    public async ValueTask<SubscribeGetViewModel?> GetById(int id)
    {
        var subscribe = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (subscribe is not null)
        {
            return new SubscribeGetViewModel
            {
                Id = subscribe.Id,
                CreatedPartyId = subscribe.CreatedPartyId,
                SubscriberPartyId = subscribe.SubscriberPartyId,
                CreateDate = subscribe.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdateSubscribeViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.CreatedPartyId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "CreatedPartyId must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        if (viewModel.SubscriberPartyId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "SubscriberPartyId must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.NullOrWhiteSpace;

            return resultViewModel;
        }

        await _artemisDbContext.Subscribes.AddAsync(new Subscribe
        {
            CreatedPartyId = viewModel.CreatedPartyId,
            SubscriberPartyId = viewModel.SubscriberPartyId
        });
        _artemisDbContext.SaveChanges();

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }


    public async ValueTask<ResultViewModel> Update(CreateOrUpdateSubscribeViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var subscribe = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (subscribe is not null)
        {
            if (subscribe.CreatedPartyId != viewModel.CreatedPartyId)
                subscribe.CreatedPartyId = viewModel.CreatedPartyId;
            
            
            if (subscribe.SubscriberPartyId != viewModel.SubscriberPartyId)
                subscribe.SubscriberPartyId = viewModel.SubscriberPartyId;
            
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

        var subscribe = await _artemisDbContext.Subscribes.FirstOrDefaultAsync(i => i.Id == id);

        if (subscribe is not null)
        {
            _artemisDbContext.Subscribes.Remove(subscribe);
            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}