using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class TopicEntityTypeConfiguration : IEntityTypeConfiguration<Topic>
    {
        public void Configure(EntityTypeBuilder<Topic> builder)
        {
            builder.HasKey(t => t.Id);
            builder.Property(t => t.Id).UseHiLo("Topic_hilo").IsRequired();
            builder.Property(t => t.Title).IsRequired();
            builder.Property(t => t.LocationX).IsRequired();
            builder.Property(t => t.LocationY).IsRequired();
            builder.Property(t => t.CategoryId).IsRequired();
            builder.Property(t => t.MentionId);
            builder.Property(t => t.Upvote).IsRequired();
            builder.Property(t => t.Downvote).IsRequired();
            builder.Property(t => t.LastUpdateDate).IsRequired();
            
            builder.HasOne(t => t.Category)
                   .WithMany()
                   .HasForeignKey(t => t.CategoryId)
                   .OnDelete(DeleteBehavior.Cascade);
        }
    }
}