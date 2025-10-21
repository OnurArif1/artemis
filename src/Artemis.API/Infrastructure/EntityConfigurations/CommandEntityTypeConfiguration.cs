using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class CommandEntityTypeConfiguration : IEntityTypeConfiguration<Command>
{
    public void Configure(EntityTypeBuilder<Command> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).UseHiLo("Command_hilo").IsRequired();
        builder.Property(c => c.TopicId).IsRequired();
        builder.Property(c => c.Topic).IsRequired();
        builder.Property(c => c.PartyId).IsRequired();
        builder.Property(c => c.Upvote).IsRequired();
        builder.Property(c => c.Downvote).IsRequired();

        builder.HasOne(c => c.Topic)
            .WithMany()
            .HasForeignKey(c => c.TopicId)
            .OnDelete(DeleteBehavior.Cascade);
    
        builder.HasOne(c => c.Party)
            .WithMany()
            .HasForeignKey(c => c.PartyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}