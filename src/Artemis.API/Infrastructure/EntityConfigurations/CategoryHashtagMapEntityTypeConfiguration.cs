using Artemis.API.Entities;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class CategoryHashtagMapEntityTypeConfiguration : IEntityTypeConfiguration<CategoryHashtagMap>
    {

        public void Configure(EntityTypeBuilder<CategoryHashtagMap> builder)
        {
            builder.ToTable("CategoryHashtagMap");
            builder.HasKey(keyExpression: chm => chm.Id);
            builder.Property(c => c.Id).UseHiLo("CategoryHashtagMap_hilo").IsRequired();
            builder.Property(chm => chm.CategoryId).IsRequired();
            builder.Property(chm => chm.HashtagId).IsRequired();

             builder.HasOne(m => m.Category)
                .WithMany()
                .HasForeignKey(m => m.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}

