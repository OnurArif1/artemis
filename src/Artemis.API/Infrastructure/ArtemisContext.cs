

using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Infrastructure;

public class ArtemisContext : DbContext
{
    public ArtemisContext(DbContextOptions<ArtemisContext> options) : base(options)
    {
    }

    
}