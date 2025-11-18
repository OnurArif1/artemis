using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Navigation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Topic",
                type: "integer",
                nullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "PartyId",
                table: "Room",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Party",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RoomId",
                table: "Category",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PartyRoom",
                columns: table => new
                {
                    PartiesId = table.Column<int>(type: "integer", nullable: false),
                    RoomsId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PartyRoom", x => new { x.PartiesId, x.RoomsId });
                    table.ForeignKey(
                        name: "FK_PartyRoom_Party_PartiesId",
                        column: x => x.PartiesId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PartyRoom_Room_RoomsId",
                        column: x => x.RoomsId,
                        principalTable: "Room",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Room_CategoryId",
                table: "Room",
                column: "CategoryId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Room_TopicId",
                table: "Room",
                column: "TopicId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PartyRoom_RoomsId",
                table: "PartyRoom",
                column: "RoomsId");

            migrationBuilder.AddForeignKey(
                name: "FK_Room_Category_CategoryId",
                table: "Room",
                column: "CategoryId",
                principalTable: "Category",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Room_Topic_TopicId",
                table: "Room",
                column: "TopicId",
                principalTable: "Topic",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Room_Category_CategoryId",
                table: "Room");

            migrationBuilder.DropForeignKey(
                name: "FK_Room_Topic_TopicId",
                table: "Room");

            migrationBuilder.DropTable(
                name: "PartyRoom");

            migrationBuilder.DropIndex(
                name: "IX_Room_CategoryId",
                table: "Room");

            migrationBuilder.DropIndex(
                name: "IX_Room_TopicId",
                table: "Room");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Topic");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Party");

            migrationBuilder.DropColumn(
                name: "RoomId",
                table: "Category");

            migrationBuilder.AlterColumn<int>(
                name: "PartyId",
                table: "Room",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);
        }
    }
}
