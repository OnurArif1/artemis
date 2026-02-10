using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class InterestEntityTypeConfiguration : IEntityTypeConfiguration<Interest>
{
    public void Configure(EntityTypeBuilder<Interest> builder)
    {
        builder.ToTable("Interest");
        builder.HasKey(i => i.Id);
        builder.Property(i => i.Id).UseHiLo("Interest_hilo").IsRequired();
        builder.Property(i => i.Name).IsRequired();
        builder.Property(i => i.CreateDate).IsRequired();
    }
}
