using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PartyPurposeService : IPartyPurposeService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public PartyPurposeService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask SavePartyPurposesAsync(string email, List<PartyPurposeType> purposeTypes)
    {
        if (string.IsNullOrEmpty(email))
        {
            throw new ArgumentException("Email is required.", nameof(email));
        }

        if (purposeTypes == null || !purposeTypes.Any())
        {
            throw new ArgumentException("At least one purpose must be selected.", nameof(purposeTypes));
        }

        // Filter out NotSet
        var validPurposeTypes = purposeTypes.Where(pt => pt != PartyPurposeType.NotSet).ToList();
        
        if (!validPurposeTypes.Any())
        {
            throw new ArgumentException("At least one valid purpose must be selected.", nameof(purposeTypes));
        }

        // Find Party by email
        var party = await _artemisDbContext.Parties
            .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == email.ToLower());

        if (party == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        // Remove existing purposes
        var existingPartyPurposes = await _artemisDbContext.PartyPurposes
            .Where(pp => pp.PartyId == party.Id)
            .ToListAsync();

        _artemisDbContext.PartyPurposes.RemoveRange(existingPartyPurposes);

        // Add new purposes
        var partyPurposes = validPurposeTypes.Select(purposeType => new PartyPurpose
        {
            PartyId = party.Id,
            PurposeType = purposeType,
            CreateDate = DateTime.UtcNow
        }).ToList();

        await _artemisDbContext.PartyPurposes.AddRangeAsync(partyPurposes);
        await _artemisDbContext.SaveChangesAsync();
    }
}
