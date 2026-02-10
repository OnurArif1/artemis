using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class InterestService : IInterestService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public InterestService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask<List<InterestViewModel>> GetListAsync()
    {
        var interests = await _artemisDbContext.Interests
            .OrderBy(i => i.Name)
            .Select(i => new InterestViewModel
            {
                Id = i.Id,
                Name = i.Name
            })
            .AsNoTracking()
            .ToListAsync();

        return interests;
    }
}
