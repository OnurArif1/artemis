namespace Artemis.API.Services;

public class RoomFilterViewModel
{
    public int PageSize { get; set; }
    public int PageIndex { get; set; }
    public string? Title { get; set; }
    public int? TopicId { get; set; }
    public double? UserLatitude { get; set; }
    public double? UserLongitude { get; set; }
    public string? UserEmail { get; set; }
}