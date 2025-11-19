using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class MessageEntityTypeConfiguration : IEntityTypeConfiguration<Message>
    {
        public void Configure(EntityTypeBuilder<Message> builder)
        {
            builder.ToTable("Message");
            builder.HasKey(m => m.Id);
            builder.Property(propertyExpression: m => m.Id).UseHiLo("Message_hilo").IsRequired();
            builder.Property(m => m.RoomId);
            builder.Property(m => m.PartyId);
            builder.Property(m => m.Upvote);
            builder.Property(m => m.Downvote);
            builder.Property(m => m.LastUpdateDate);

            builder.HasOne(m => m.Room)
                .WithMany()
                .HasForeignKey(m => m.RoomId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(m => m.Party)
                .WithMany()
                .HasForeignKey(m => m.PartyId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(m => m.Room)
                .WithMany(r => r.Messages)
                .HasForeignKey(m => m.RoomId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}