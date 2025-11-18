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
            builder.Property(r => r.Title);
            builder.Property(r => r.LocationX);
            builder.Property(r => r.LocationY);
            builder.Property(r => r.LifeCycle);
            builder.Property(r => r.ChannelId);
            builder.Property(r => r.ReferenceId);
            builder.Property(r => r.Upvote);
            builder.Property(r => r.Downvote);

            builder.HasOne(r => r.Category)
                .WithOne(c => c.Room)
                .HasForeignKey<Room>(r => r.CategoryId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(r => r.Topic)
                .WithOne(t => t.Room)
                .HasForeignKey<Room>(r => r.TopicId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasMany(r => r.Parties)
                .WithMany(p => p.Rooms)
                .UsingEntity(j => j.ToTable("PartyRoom"));
        }
    }
}