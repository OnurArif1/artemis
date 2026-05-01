using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveTopicTypeFromTopic : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Topic_Mention_MentionId1",
                table: "Topic");

            migrationBuilder.DropIndex(
                name: "IX_Topic_MentionId1",
                table: "Topic");

            migrationBuilder.DropColumn(
                name: "MentionId1",
                table: "Topic");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "Topic");

            migrationBuilder.CreateIndex(
                name: "IX_Topic_MentionId",
                table: "Topic",
                column: "MentionId");

            migrationBuilder.AddForeignKey(
                name: "FK_Topic_Mention_MentionId",
                table: "Topic",
                column: "MentionId",
                principalTable: "Mention",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Topic_Mention_MentionId",
                table: "Topic");

            migrationBuilder.DropIndex(
                name: "IX_Topic_MentionId",
                table: "Topic");

            migrationBuilder.AddColumn<int>(
                name: "MentionId1",
                table: "Topic",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "Topic",
                type: "integer",
                nullable: false,
                defaultValue: 0);

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
        }
    }
}
