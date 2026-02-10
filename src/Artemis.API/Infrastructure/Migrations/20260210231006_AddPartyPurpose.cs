using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPartyPurpose : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence(
                name: "PartyPurpose_hilo",
                incrementBy: 10);

            migrationBuilder.CreateTable(
                name: "PartyPurpose",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    PurposeType = table.Column<int>(type: "integer", nullable: false),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    CreateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PartyPurpose", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PartyPurpose_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PartyPurpose_PartyId",
                table: "PartyPurpose",
                column: "PartyId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PartyPurpose");

            migrationBuilder.DropSequence(
                name: "PartyPurpose_hilo");
        }
    }
}
