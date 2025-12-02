using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveUniqueConstraintFromRoomTopicId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Room_TopicId",
                table: "Room");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Topic");

            migrationBuilder.CreateIndex(
                name: "IX_Room_TopicId",
                table: "Room",
                column: "TopicId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Room_TopicId",
                table: "Room");

            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Topic",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Room_TopicId",
                table: "Room",
                column: "TopicId",
                unique: true);
        }
    }
}
