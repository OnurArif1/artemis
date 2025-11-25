using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveUniqueConstraintFromRoomCategoryId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Room_CategoryId",
                table: "Room");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_Room_CategoryId",
                table: "Room",
                column: "CategoryId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Room_CategoryId",
                table: "Room");

            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Category",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Room_CategoryId",
                table: "Room",
                column: "CategoryId",
                unique: true);
        }
    }
}
