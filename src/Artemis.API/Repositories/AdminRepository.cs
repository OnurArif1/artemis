using Artemis.API.Abstract;
using Artemis.API.Data;
using src.Artemis.API.Entities;

namespace Artemis.API.Repositories
{
    public class AdminRepository : GenericRepository<Admin>, IAdmin
    {
        public AdminRepository(ApplicationDbContext context) : base(context)
        {
        }
    }
}



