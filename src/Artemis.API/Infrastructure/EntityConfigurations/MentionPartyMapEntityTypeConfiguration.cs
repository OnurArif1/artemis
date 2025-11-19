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

        builder.HasOne(m => m.Party)
            .WithMany(p => p.MentionPartyMaps)
            .HasForeignKey(m => m.PartyId)
            .OnDelete(DeleteBehavior.Cascade);


            builder
            .HasOne(mp => mp.Mention)
            .WithMany(m => m.MentionPartyMaps)
            .HasForeignKey(mp => mp.MentionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder
            .HasOne(mp => mp.Party)
            .WithMany(p => p.MentionPartyMaps)
            .HasForeignKey(mp => mp.PartyId)
            .OnDelete(DeleteBehavior.Cascade);

    }
}