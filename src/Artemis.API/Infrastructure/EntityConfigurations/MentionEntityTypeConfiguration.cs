using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class MentionEntityTypeConfiguration : IEntityTypeConfiguration<Mention>
{
    public void Configure(EntityTypeBuilder<Mention> builder)
    {
        builder.ToTable("Mention");

        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).UseHiLo("Mention_hilo").IsRequired();
        builder.Property(c => c.RoomId);
        builder.Property(c => c.MessageId);
        builder.Property(c => c.CommentId);
        builder.Property(c => c.TopicId);

        builder.HasOne(c => c.Topic)
            .WithMany()
            .HasForeignKey(c => c.TopicId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(c => c.Room)
            .WithMany()
            .HasForeignKey(c => c.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Message)
            .WithMany()
            .HasForeignKey(c => c.MessageId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Comment)
            .WithMany()
            .HasForeignKey(c => c.CommentId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}