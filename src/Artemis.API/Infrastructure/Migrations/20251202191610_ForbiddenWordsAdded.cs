using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ForbiddenWordsAdded : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence(
                name: "ForbiddenWord_hilo",
                incrementBy: 10);

            migrationBuilder.CreateTable(
                name: "ForbiddenWord",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    Word = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ForbiddenWord", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ForbiddenWord_Word",
                table: "ForbiddenWord",
                column: "Word",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ForbiddenWord");

            migrationBuilder.DropSequence(
                name: "ForbiddenWord_hilo");
        }
    }
}
