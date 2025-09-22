using Artemis.API.Abstract;
using Artemis.API.Data;
using src.Artemis.API.Entities;

namespace Artemis.API.Repositories
{
    public class PostRepository : GenericRepository<Post>, IPost
    {
        public PostRepository(ApplicationDbContext context) : base(context)
        {
        }
    }
}


