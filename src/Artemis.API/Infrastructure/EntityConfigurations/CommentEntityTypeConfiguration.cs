using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations;

public class CommentEntityTypeConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.ToTable("Comment");

        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).UseHiLo("Comment_hilo").IsRequired();
        builder.Property(c => c.TopicId);
        builder.Property(c => c.PartyId);
        builder.Property(c => c.Upvote);
        builder.Property(c => c.Downvote);

        builder.HasOne(c => c.Topic)
            .WithMany()
            .HasForeignKey(c => c.TopicId)
            .OnDelete(DeleteBehavior.Cascade);
    
        builder.HasOne(c => c.Party)
            .WithMany()
            .HasForeignKey(c => c.PartyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Topic)
            .WithMany(t => t.Comments)
            .HasForeignKey(c => c.TopicId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}