using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class PartyPurposeEntityTypeConfiguration : IEntityTypeConfiguration<PartyPurpose>
{
    public void Configure(EntityTypeBuilder<PartyPurpose> builder)
    {
        builder.ToTable("PartyPurpose");

        builder.HasKey(pp => pp.Id);
        builder.Property(pp => pp.Id).UseHiLo("PartyPurpose_hilo").IsRequired();
        builder.Property(pp => pp.PurposeType).IsRequired();
        builder.Property(pp => pp.PartyId).IsRequired();
        builder.Property(pp => pp.CreateDate).IsRequired();

        builder.HasOne(pp => pp.Party)
            .WithMany(p => p.PartyPurposes)
            .HasForeignKey(pp => pp.PartyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
