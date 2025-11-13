using Artemis.API.Entities.Enums;

namespace Artemis.API.Services;

public class ResultViewModel
{
    public bool IsSuccess { get; set; }
    public string? ExceptionMessage { get; set; }
    public ExceptionType? ExceptionType { get; set; }
}