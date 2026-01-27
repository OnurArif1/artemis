using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPartyEmailUnique : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "Party",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Party_Email",
                table: "Party",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Party_Email",
                table: "Party");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "Party");
        }
    }
}
