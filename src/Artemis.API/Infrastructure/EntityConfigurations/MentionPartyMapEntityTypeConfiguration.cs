using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class MentionPartyMapEntityTypeConfiguration : IEntityTypeConfiguration<MentionPartyMap>
{
    public void Configure(EntityTypeBuilder<MentionPartyMap> builder)
    {
        builder.ToTable("MentionPartyMap");

        builder.HasKey(mpm => mpm.Id);
        builder.Property(mpm => mpm.Id).UseHiLo("MentionPartyMap_hilo").IsRequired();
        builder.Property(mpm => mpm.MentionId);
        builder.Property(mpm => mpm.PartyId);

        builder.HasOne(mpm => mpm.Mention)
            .WithMany()
            .HasForeignKey(mpm => mpm.MentionId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(mpm => mpm.Party)
            .WithMany()
            .HasForeignKey(mpm => mpm.PartyId)
            .OnDelete(DeleteBehavior.Cascade);

    }
}