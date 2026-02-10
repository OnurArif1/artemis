using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PartyService : IPartyService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public PartyService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdatePartyViewModel viewModel)
    {
        var party = new Party()
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId,
            CreateDate = viewModel.CreateDate
        };
        await _artemisDbContext.Parties.AddAsync(party);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<PartyListViewModel> GetList(PartyFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Parties.AsQueryable();
        var count = await query.CountAsync();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            query = query.Where(x => x.PartyName.Contains(filterViewModel.Title));
        }

        var parties = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new PartyResultViewModel
            {
                Id = r.Id,
                PartyName = r.PartyName,
                PartyType = r.PartyType,
                IsBanned = r.IsBanned,
                DeviceId = r.DeviceId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new PartyListViewModel
        {
            Count = count,
            ResultViewmodels = parties
        };
    }

    public async ValueTask Update(CreateOrUpdatePartyViewModel viewModel)
    {
        var query = _artemisDbContext.Parties.AsQueryable();
        var party = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (party is not null)
        {
            party.PartyName = viewModel.PartyName;
            party.Description = viewModel.Description;
            party.PartyType = viewModel.PartyType;
            party.IsBanned = viewModel.IsBanned;
            party.DeviceId = viewModel.DeviceId;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask UpdateByEmail(string email, string partyName, string? description)
    {
        if (string.IsNullOrEmpty(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        var party = await _artemisDbContext.Parties
            .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == email.ToLower());

        if (party == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        party.PartyName = partyName;
        party.Description = description;
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<ResultPartyLookupViewModel> GetPartyLookup(GetLookupPartyViewModel viewModel)
    {
        var query = _artemisDbContext.Parties.AsQueryable();

        if (!string.IsNullOrWhiteSpace(viewModel.SearchText))
        {
            if (viewModel.PartyLookupSearchType == PartyLookupSearchType.PartyName)
            {
                query = query.Where(x => x.PartyName.Contains(viewModel.SearchText));
            }

            if (viewModel.PartyLookupSearchType == PartyLookupSearchType.PartyId)
            {
                if (int.TryParse(viewModel.SearchText, out int partyId))
                {
                    query = query.Where(x => x.Id == partyId);
                }
            }

            if (viewModel.PartyLookupSearchType == PartyLookupSearchType.Email)
            {
                query = query.Where(x => x.Email != null && x.Email.ToLower() == viewModel.SearchText.ToLower());
            }
        }

        if (viewModel.PartyId.HasValue)
        {
            query = query.Where(x => x.Id == viewModel.PartyId.Value);
        }

        var parties = await query
            .OrderBy(x => x.PartyName)
            .Select(p => new PartyLookupViewModel
            {
                PartyId = p.Id,
                PartyName = p.PartyName
            })
            .ToListAsync();

        return new ResultPartyLookupViewModel
        {
            Count = parties.Count,
            ViewModels = parties
        };
    }

    public async ValueTask Delete(int id)
    {
        var party = await _artemisDbContext.Parties
            .FirstOrDefaultAsync(i => i.Id == id);
        if (party is not null)
        {
            _artemisDbContext.Parties.Remove(party);
            await _artemisDbContext.SaveChangesAsync();
        }
    }

}