using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PartyInterestService : IPartyInterestService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public PartyInterestService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask SavePartyInterestsAsync(string email, List<int> interestIds)
    {
        if (string.IsNullOrEmpty(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        if (interestIds == null || !interestIds.Any())
        {
            throw new ArgumentException("At least one interest must be selected.", nameof(interestIds));
        }

        // Find Party by email
        var party = await _artemisDbContext.Parties
            .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == email.ToLower());

        if (party == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        // Remove existing interests
        var existingPartyInterests = await _artemisDbContext.PartyInterests
            .Where(pi => pi.PartyId == party.Id)
            .ToListAsync();

        _artemisDbContext.PartyInterests.RemoveRange(existingPartyInterests);

        // Add new interests
        var partyInterests = interestIds.Select(interestId => new PartyInterest
        {
            PartyId = party.Id,
            InterestId = interestId,
            CreateDate = DateTime.UtcNow
        }).ToList();

        await _artemisDbContext.PartyInterests.AddRangeAsync(partyInterests);
        await _artemisDbContext.SaveChangesAsync();
    }

    public async ValueTask<List<InterestViewModel>> GetMyInterestsAsync(string email)
    {
        if (string.IsNullOrEmpty(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        // Find Party by email
        var party = await _artemisDbContext.Parties
            .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == email.ToLower());

        if (party == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        // Get user's interests
        var interests = await _artemisDbContext.PartyInterests
            .Where(pi => pi.PartyId == party.Id)
            .Include(pi => pi.Interest)
            .Select(pi => new InterestViewModel
            {
                Id = pi.Interest!.Id,
                Name = pi.Interest.Name
            })
            .AsNoTracking()
            .ToListAsync();

        return interests;
    }
}
