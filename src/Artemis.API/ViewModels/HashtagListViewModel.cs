using Artemis.API.Entities.Enums;

namespace Artemis.API.Services
{
    public class HashtagListViewModel
    {
        public int? Count { get; set; }
        public IEnumerable<HashtagResultViewModel> ResultViewmodels { get; set; } = new List<HashtagResultViewModel>();
    }

    public class HashtagResultViewModel
    {
        public int Id { get; set; }
        public string HashtagName { get; set; }
        public DateTime CreateDate { get; set; }
    }
}
