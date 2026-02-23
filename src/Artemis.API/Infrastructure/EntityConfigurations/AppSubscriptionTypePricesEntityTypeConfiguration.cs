using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class AppSubscriptionTypePricesEntityTypeConfiguration : IEntityTypeConfiguration<AppSubscriptionTypePrices>
    {
        public void Configure(EntityTypeBuilder<AppSubscriptionTypePrices> builder)
        {
            builder.ToTable("AppSubscriptionTypePrices");
            builder.HasKey(a => a.Id);
            builder.Property(a => a.Id).UseHiLo("AppSubscriptionTypePrices_hilo").IsRequired();
            builder.Property(a => a.SubscriptionType).IsRequired();
            builder.Property(a => a.Price).HasColumnType("decimal(18,2)").IsRequired();
            builder.Property(a => a.PriceCurrencyType).IsRequired();
            builder.Property(a => a.AppSubscriptionPeriodType);
            builder.Property(a => a.CreateDate).IsRequired();
            builder.Property(a => a.ThruDate);
        }
    }
}
