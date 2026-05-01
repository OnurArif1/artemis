using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Infrastructure;

internal static class PartyLoginLookup
{
    internal static async Task<Party?> FindPartyForLoginEmailAsync(
        this IQueryable<Party> parties,
        string email,
        CancellationToken cancellationToken = default)
    {
        var trimmed = email.Trim();
        var lowered = trimmed.ToLowerInvariant();

        var party = await parties
            .FirstOrDefaultAsync(
                p => p.Email != null && p.Email.ToLower() == lowered,
                cancellationToken);

        if (party != null)
        {
            return party;
        }

        return await parties
            .FirstOrDefaultAsync(p => p.PartyName.ToLower() == lowered, cancellationToken);
    }

    internal static void EnsurePartyEmail(Party party, string email)
    {
        if (!string.IsNullOrWhiteSpace(party.Email))
        {
            return;
        }

        party.Email = email.Trim();
    }
}
