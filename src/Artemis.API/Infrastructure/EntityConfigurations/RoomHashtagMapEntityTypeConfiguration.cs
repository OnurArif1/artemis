using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class RoomHashtagMapEntityTypeConfiguration : IEntityTypeConfiguration<RoomHashtagMap>
    {
        public void Configure(EntityTypeBuilder<RoomHashtagMap> builder)
        {
            builder.ToTable("RoomHashtagMap");
            builder.HasKey(rhm => rhm.Id);
            builder.Property(rhm => rhm.Id).UseHiLo("RoomHashtagMap_hilo").IsRequired();
            builder.Property(rhm => rhm.RoomId);
            builder.Property(rhm => rhm.HashtagId);

            builder.HasOne(rhm => rhm.Room)
                .WithMany()
                .HasForeignKey(rhm => rhm.RoomId)
                .OnDelete(DeleteBehavior.Cascade);
            
            builder.HasOne(rhm => rhm.Hashtag)
                .WithMany()
                .HasForeignKey(rhm => rhm.HashtagId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
