using Artemis.API.Entities;
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

    public async ValueTask Create(Party party)
    {
        // todo ask. how to unique rooms?
        await _artemisDbContext.Parties.AddAsync(party);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<IEnumerable<PartyGetViewModel>> GetList(PartyFilterViewModel filterViewModel)
    {
        var query = (from r in _artemisDbContext.Parties
                     select new { r }).AsQueryable();

        var count = await query.CountAsync();
        query = query.OrderByDescending(i => i.r.CreateDate)
                     .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
                     .Take(filterViewModel.PageSize);

        var parties = await (query.Select(rg => new PartyGetViewModel()
        {
            Id = rg.r.Id,
            Count = count
        })).AsNoTracking().ToListAsync();

        return parties;
    }
    
    public async ValueTask<int?> GetPartyIdByName(string partyName)
    {
        if (string.IsNullOrWhiteSpace(partyName))
            return null;

        var id = await _artemisDbContext.Parties
            .AsNoTracking()
            .Where(p => p.PartyName == partyName)
            .Select(p => (int?)p.Id)
            .FirstOrDefaultAsync();

        return id;
    }

    public async ValueTask<string?> GetPartyNameById(int partyId)
    {
        var name = await _artemisDbContext.Parties
            .AsNoTracking()
            .Where(p => p.Id == partyId)
            .Select(p => p.PartyName)
            .FirstOrDefaultAsync();

        return name;
    }

}