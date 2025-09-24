using Artemis.API.Abstract;
using Artemis.API.Data;
using src.Artemis.API.Entities;

namespace Artemis.API.Repositories
{
    public class CommentRepository : GenericRepository<Comment>, IComment
    {
        public CommentRepository(ApplicationDbContext context) : base(context)
        {
        }
    }
}


