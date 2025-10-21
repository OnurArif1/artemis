using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class SubscribeEntityTypeConfiguration : IEntityTypeConfiguration<Subscribe>
    {
        public void Configure(EntityTypeBuilder<Subscribe> builder)
        {
            builder.ToTable("Subscribe");
            builder.HasKey(s => s.Id);
            builder.Property(s => s.Id).UseHiLo("Subscribe_hilo").IsRequired();
            builder.Property(s => s.CreatedPartyId);
            builder.Property(s => s.SubscriberPartyId);

            builder.HasOne(s => s.CreatedParty)
                .WithMany()
                .HasForeignKey(s => s.CreatedPartyId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(s => s.SubscriberParty)
                .WithMany()
                .HasForeignKey(s => s.SubscriberPartyId)
                .OnDelete(DeleteBehavior.Cascade);           
        }
    }
}
