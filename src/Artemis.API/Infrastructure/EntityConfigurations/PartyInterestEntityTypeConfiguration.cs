using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class PartyInterestEntityTypeConfiguration : IEntityTypeConfiguration<PartyInterest>
{
    public void Configure(EntityTypeBuilder<PartyInterest> builder)
    {
        builder.ToTable("PartyInterest");

        builder.HasKey(pi => pi.Id);
        builder.Property(pi => pi.Id).UseHiLo("PartyInterest_hilo").IsRequired();
        builder.Property(pi => pi.InterestId).IsRequired();
        builder.Property(pi => pi.PartyId).IsRequired();
        builder.Property(pi => pi.CreateDate).IsRequired();

        builder.HasOne(pi => pi.Party)
            .WithMany(p => p.PartyInterests)
            .HasForeignKey(pi => pi.PartyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(pi => pi.Interest)
            .WithMany(i => i.PartyInterests)
            .HasForeignKey(pi => pi.InterestId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
