using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class TopicEntityTypeConfiguration : IEntityTypeConfiguration<Topic>
    {
        public void Configure(EntityTypeBuilder<Topic> builder)
        {
            builder.ToTable("Topic");

            builder.HasKey(t => t.Id);
            builder.Property(t => t.Id).UseHiLo("Topic_hilo").IsRequired();
            builder.Property(t => t.Title);
            builder.Property(t => t.LocationX);
            builder.Property(t => t.LocationY);
            builder.Property(t => t.CategoryId);
            builder.Property(t => t.MentionId);
            builder.Property(t => t.Upvote);
            builder.Property(t => t.Downvote);
            builder.Property(t => t.LastUpdateDate);
            
            builder.HasOne(t => t.Category)
                   .WithMany()
                   .HasForeignKey(t => t.CategoryId)
                   .OnDelete(DeleteBehavior.Cascade);
        }
    }
}