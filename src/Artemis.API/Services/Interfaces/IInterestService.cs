namespace Artemis.API.Services.Interfaces;

public interface IInterestService
{
    ValueTask<List<InterestViewModel>> GetListAsync();
}

public class InterestViewModel
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}
