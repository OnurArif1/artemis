using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ChangedColumnTypeForRoomTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Type",
                table: "Room");

            migrationBuilder.AddColumn<int>(
                name: "RoomType",
                table: "Room",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RoomType",
                table: "Room");

            migrationBuilder.AddColumn<double>(
                name: "Type",
                table: "Room",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0);
        }
    }
}
