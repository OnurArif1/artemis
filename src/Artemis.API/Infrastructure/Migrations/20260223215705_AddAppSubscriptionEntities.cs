using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAppSubscriptionEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence(
                name: "AppSubscription_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "AppSubscriptionTypePrices_hilo",
                incrementBy: 10);

            migrationBuilder.AddColumn<double>(
                name: "RoomRange",
                table: "Room",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SubscriptionType",
                table: "Room",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SubscriptionType",
                table: "Party",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AppSubscriptionTypePrices",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    SubscriptionType = table.Column<int>(type: "integer", nullable: false),
                    Price = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PriceCurrencyType = table.Column<int>(type: "integer", nullable: false),
                    AppSubscriptionPeriodType = table.Column<int>(type: "integer", nullable: true),
                    CreateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ThruDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppSubscriptionTypePrices", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AppSubscription",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    AppSubscriptionTypePriceId = table.Column<int>(type: "integer", nullable: false),
                    CreateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppSubscription", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppSubscription_AppSubscriptionTypePrices_AppSubscriptionTy~",
                        column: x => x.AppSubscriptionTypePriceId,
                        principalTable: "AppSubscriptionTypePrices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AppSubscription_Party_UserId",
                        column: x => x.UserId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AppSubscription_AppSubscriptionTypePriceId",
                table: "AppSubscription",
                column: "AppSubscriptionTypePriceId");

            migrationBuilder.CreateIndex(
                name: "IX_AppSubscription_UserId",
                table: "AppSubscription",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AppSubscription");

            migrationBuilder.DropTable(
                name: "AppSubscriptionTypePrices");

            migrationBuilder.DropColumn(
                name: "RoomRange",
                table: "Room");

            migrationBuilder.DropColumn(
                name: "SubscriptionType",
                table: "Room");

            migrationBuilder.DropColumn(
                name: "SubscriptionType",
                table: "Party");

            migrationBuilder.DropSequence(
                name: "AppSubscription_hilo");

            migrationBuilder.DropSequence(
                name: "AppSubscriptionTypePrices_hilo");
        }
    }
}
