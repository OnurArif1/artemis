using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Fix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Room_Category_CategoryId",
                table: "Room");

            migrationBuilder.DropForeignKey(
                name: "FK_Room_Party_PartyId",
                table: "Room");

            migrationBuilder.DropIndex(
                name: "IX_Room_CategoryId",
                table: "Room");

            migrationBuilder.DropIndex(
                name: "IX_Room_PartyId",
                table: "Room");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_Room_CategoryId",
                table: "Room",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Room_PartyId",
                table: "Room",
                column: "PartyId");

            migrationBuilder.AddForeignKey(
                name: "FK_Room_Category_CategoryId",
                table: "Room",
                column: "CategoryId",
                principalTable: "Category",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Room_Party_PartyId",
                table: "Room",
                column: "PartyId",
                principalTable: "Party",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
