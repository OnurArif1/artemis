using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class AppSubscriptionEntityTypeConfiguration : IEntityTypeConfiguration<AppSubscription>
    {
        public void Configure(EntityTypeBuilder<AppSubscription> builder)
        {
            builder.ToTable("AppSubscription");
            builder.HasKey(a => a.Id);
            builder.Property(a => a.Id).UseHiLo("AppSubscription_hilo").IsRequired();
            builder.Property(a => a.UserId).IsRequired();
            builder.Property(a => a.AppSubscriptionTypePriceId).IsRequired();
            builder.Property(a => a.CreateDate).IsRequired();
            builder.Property(a => a.StartDate).IsRequired();
            builder.Property(a => a.EndDate).IsRequired();
            builder.Property(a => a.IsActive).IsRequired();

            builder.HasOne(a => a.UserParty)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(a => a.AppSubscriptionTypePrice)
                .WithMany()
                .HasForeignKey(a => a.AppSubscriptionTypePriceId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
