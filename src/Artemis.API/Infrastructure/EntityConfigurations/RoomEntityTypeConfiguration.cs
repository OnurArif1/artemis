using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class RoomEntityTypeConfiguration : IEntityTypeConfiguration<Room>
    {
        public void Configure(EntityTypeBuilder<Room> builder)
        {
            builder.ToTable("Room");
            builder.HasKey(r => r.Id);
            builder.Property(r => r.Id).UseHiLo("Room_hilo").IsRequired();
            builder.Property(r => r.Title).IsRequired();
            builder.Property(r => r.LocationX).IsRequired();
            builder.Property(r => r.LocationY).IsRequired();
            builder.Property(r => r.Type).IsRequired();
            builder.Property(r => r.LifeCycle).IsRequired();
            builder.Property(r => r.ChannelId).IsRequired();
            builder.Property(r => r.ReferenceId).IsRequired();
            builder.Property(r => r.Upvote).IsRequired();
            builder.Property(r => r.Downvote).IsRequired();
        }
    }
}