using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class HashtagEntityTypeConfiguration : IEntityTypeConfiguration<Hashtag>
    {
        public void Configure(EntityTypeBuilder<Hashtag> builder)
        {
            builder.ToTable("Hashtag");
            builder.HasKey(h => h.Id);
            builder.Property(h => h.Id).UseHiLo("Hashtag_hilo").IsRequired();
            builder.Property(h => h.HashtagName);
        }
    }
}
