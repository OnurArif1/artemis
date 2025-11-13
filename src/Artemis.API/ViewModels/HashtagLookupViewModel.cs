using Artemis.API.Entities.Enums;

namespace Artemis.API.Services
{
    public class HashtagLookupViewModel
    {
        public int? HashtagId { get; set; }
        public string? HashtagName { get; set; }
    }

    public class ResultHashtagLookupViewModel
    {
        public int? Count { get; set; }
        public IEnumerable<HashtagLookupViewModel>? ViewModels { get; set; }
    }
}
