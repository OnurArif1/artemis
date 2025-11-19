using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class topicTableRemake : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Topic_Party_PartyId",
                table: "Topic");

            migrationBuilder.AlterColumn<int>(
                name: "Upvote",
                table: "Topic",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<int>(
                name: "PartyId",
                table: "Topic",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<double>(
                name: "LocationY",
                table: "Topic",
                type: "double precision",
                nullable: true,
                oldClrType: typeof(double),
                oldType: "double precision");

            migrationBuilder.AlterColumn<double>(
                name: "LocationX",
                table: "Topic",
                type: "double precision",
                nullable: true,
                oldClrType: typeof(double),
                oldType: "double precision");

            migrationBuilder.AlterColumn<int>(
                name: "Downvote",
                table: "Topic",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<int>(
                name: "MentionId1",
                table: "Topic",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Topic_MentionId1",
                table: "Topic",
                column: "MentionId1");

            migrationBuilder.AddForeignKey(
                name: "FK_Topic_Mention_MentionId1",
                table: "Topic",
                column: "MentionId1",
                principalTable: "Mention",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Topic_Party_PartyId",
                table: "Topic",
                column: "PartyId",
                principalTable: "Party",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Topic_Mention_MentionId1",
                table: "Topic");

            migrationBuilder.DropForeignKey(
                name: "FK_Topic_Party_PartyId",
                table: "Topic");

            migrationBuilder.DropIndex(
                name: "IX_Topic_MentionId1",
                table: "Topic");

            migrationBuilder.DropColumn(
                name: "MentionId1",
                table: "Topic");

            migrationBuilder.AlterColumn<int>(
                name: "Upvote",
                table: "Topic",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "PartyId",
                table: "Topic",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<double>(
                name: "LocationY",
                table: "Topic",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0,
                oldClrType: typeof(double),
                oldType: "double precision",
                oldNullable: true);

            migrationBuilder.AlterColumn<double>(
                name: "LocationX",
                table: "Topic",
                type: "double precision",
                nullable: false,
                defaultValue: 0.0,
                oldClrType: typeof(double),
                oldType: "double precision",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "Downvote",
                table: "Topic",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Topic_Party_PartyId",
                table: "Topic",
                column: "PartyId",
                principalTable: "Party",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
