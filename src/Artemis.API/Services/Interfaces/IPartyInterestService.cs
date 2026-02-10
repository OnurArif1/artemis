namespace Artemis.API.Services.Interfaces;

public interface IPartyInterestService
{
    ValueTask SavePartyInterestsAsync(string email, List<int> interestIds);
    ValueTask<List<InterestViewModel>> GetMyInterestsAsync(string email);
}
