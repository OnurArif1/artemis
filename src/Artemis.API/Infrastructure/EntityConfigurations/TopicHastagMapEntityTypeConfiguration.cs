using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class TopicHashtagMapEntityTypeConfiguration : IEntityTypeConfiguration<TopicHashtagMap>
    {
        public void Configure(EntityTypeBuilder<TopicHashtagMap> builder)
        {
            builder.ToTable("TopicHashtagMap");
            builder.HasKey(thm => thm.Id);
            builder.Property(thm => thm.Id).UseHiLo("TopicHashtagMap_hilo").IsRequired();
            builder.Property(thm => thm.TopicId);
            builder.Property(thm => thm.HashtagId);

            builder.HasOne(thm => thm.Hashtag)
                .WithMany()
                .HasForeignKey(thm => thm.HashtagId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(th => th.Topic)
                .WithMany(t => t.TopicHashtagMaps)
                .HasForeignKey(th => th.TopicId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(th => th.Hashtag)
                .WithMany(h => h.TopicHashtagMaps)
                .HasForeignKey(th => th.HashtagId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}

