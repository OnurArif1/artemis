using Artemis.API.Entities;
using Artemis.API.Infrastructure.EntityConfigurations;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Infrastructure;

public class ArtemisDbContext : DbContext
{
    public ArtemisDbContext(DbContextOptions<ArtemisDbContext> options) : base(options)
    {
    }

    public DbSet<Category> Categories { get; set; }
    public DbSet<CategoryHashtagMap> CategoryHashtagMaps { get; set; }
    public DbSet<Comment> Comments { get; set; }
    public DbSet<Hashtag> Hashtags { get; set; }
    public DbSet<Mention> Mentions { get; set; }
    public DbSet<MentionPartyMap> MentionPartyMaps { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<Organization> Organizations { get; set; }
    public DbSet<Party> Parties { get; set; }
    public DbSet<Person> People { get; set; }
    public DbSet<Room> Rooms { get; set; }
    public DbSet<RoomHashtagMap> RoomHashtags { get; set; }
    public DbSet<Subscribe> Subscribes { get; set; }
    public DbSet<Topic> Topics { get; set; }
    public DbSet<TopicHashtagMap> TopicHashtagMaps { get; set; }
    public DbSet<ForbiddenWord> ForbiddenWords { get; set; }
    public DbSet<Interest> Interests { get; set; }
    public DbSet<PartyInterest> PartyInterests { get; set; }
    public DbSet<PartyPurpose> PartyPurposes { get; set; }
    public DbSet<AppSubscription> AppSubscriptions { get; set; }
    public DbSet<AppSubscriptionTypePrices> AppSubscriptionTypePrices { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new CategoryEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new CategoryHashtagMapEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new CommentEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new HashtagEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new MentionEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new MentionPartyMapEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new MessageEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new OrganizationEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new PartyEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new PersonEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new RoomEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new RoomHashtagMapEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new SubscribeEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new TopicEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new TopicHashtagMapEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new ForbiddenWordEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new InterestEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new PartyInterestEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new PartyPurposeEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new AppSubscriptionEntityTypeConfiguration());
        modelBuilder.ApplyConfiguration(new AppSubscriptionTypePricesEntityTypeConfiguration());
    }

    public override int SaveChanges()
    {
        saveChanges();
        return base.SaveChanges();
    }
    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        saveChanges();
        return await base.SaveChangesAsync(cancellationToken);
    }

    private void saveChanges()
    {
        this.ChangeTracker.DetectChanges();
        var added = this.ChangeTracker.Entries()
                    .Where(t => t.State == EntityState.Added)
                    .Select(t => t.Entity)
                    .ToArray();

        foreach (var entity in added)
        {
            if (entity is IChangingDate)
            {
                var track = entity as IChangingDate;
                if (track != null)
                    track.CreateDate = DateTime.UtcNow;
            }
        }

        var modified = this.ChangeTracker.Entries()
                    .Where(t => t.State == EntityState.Modified)
                    .Select(t => t.Entity)
                    .ToArray();

        foreach (var entity in modified)
        {
            if (entity is IChangingDate)
            {
                var track = entity as IChangingDate;
            }
        }
    }

}