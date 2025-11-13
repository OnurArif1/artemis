using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class MentionPartyMapService : IMentionPartyMapService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private readonly IQueryable<MentionPartyMap> query;

    public MentionPartyMapService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.MentionPartyMaps.AsQueryable();
    }

    public async ValueTask<MentionPartyMapListViewModel> GetList(MentionPartyMapFilterViewModel filterViewModel)
    {
        var count = await query.CountAsync();

        var mentionPartyMaps = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new MentionPartyMapResultViewModel
            {
                Id = r.Id,
                MentionId = r.MentionId,
                PartyId = r.PartyId
            })
            .ToListAsync();

        return new MentionPartyMapListViewModel
        {
            Count = count,
            ResultViewModels = mentionPartyMaps
        };
    }

    public async ValueTask<MentionPartyMapGetViewModel?> GetById(int id)
    {
        var mentionPartyMap = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (mentionPartyMap is not null)
        {
            return new MentionPartyMapGetViewModel
            {
                Id = mentionPartyMap.Id,
                MentionId = mentionPartyMap.MentionId,
                PartyId = mentionPartyMap.PartyId,
                CreateDate = mentionPartyMap.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        var resultViewModel = new ResultViewModel();

        if (viewModel.PartyId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "PartyId must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        if (viewModel.MentionId <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "MentionId must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }
        
        await _artemisDbContext.MentionPartyMaps.AddAsync(new MentionPartyMap
        {
            MentionId = viewModel.MentionId,
            PartyId = viewModel.PartyId
        });
        _artemisDbContext.SaveChanges();

        resultViewModel.IsSuccess = true;

        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Update(CreateOrUpdateMentionPartyMapViewModel viewModel)
    {
        var resultViewModel = new ResultViewModel();
        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var mentionPartyMap = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (mentionPartyMap is not null)
        {
            if (mentionPartyMap.MentionId != viewModel.MentionId)
                mentionPartyMap.MentionId = viewModel.MentionId;

            if (mentionPartyMap.PartyId != viewModel.PartyId)
                mentionPartyMap.PartyId = viewModel.PartyId;

            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Delete(int id)
    {
        var resultViewModel = new ResultViewModel();

        if (id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;
            return resultViewModel;
        }

        var mentionPartyMap = await _artemisDbContext.MentionPartyMaps.FirstOrDefaultAsync(i => i.Id == id);
        if (mentionPartyMap is not null)
        {
            _artemisDbContext.MentionPartyMaps.Remove(mentionPartyMap);
            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}