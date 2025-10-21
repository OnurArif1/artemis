using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class PartyEntityTypeConfiguration : IEntityTypeConfiguration<Party>
    {
        public void Configure(EntityTypeBuilder<Party> builder)
        {
            builder.ToTable("Party");
            builder.HasKey(p => p.Id);
            builder.Property(p => p.Id).UseHiLo("Party_hilo").IsRequired();
            builder.Property(p => p.PartyName);
            builder.Property(p => p.PartyType);
            builder.Property(p => p.IsBanned);
            builder.Property(p => p.DeviceId);
        }
    }
}
