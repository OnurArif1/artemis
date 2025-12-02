using Artemis.API.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Artemis.API.Infrastructure.EntityConfigurations
{
    public class ForbiddenWordEntityTypeConfiguration : IEntityTypeConfiguration<ForbiddenWord>
    {
        public void Configure(EntityTypeBuilder<ForbiddenWord> builder)
        {
            builder.ToTable("ForbiddenWord");
            builder.HasKey(fw => fw.Id);
            builder.Property(fw => fw.Id).UseHiLo("ForbiddenWord_hilo").IsRequired();
            builder.Property(fw => fw.Word).IsRequired().HasMaxLength(200);
            builder.HasIndex(fw => fw.Word).IsUnique();
        }
    }
}

