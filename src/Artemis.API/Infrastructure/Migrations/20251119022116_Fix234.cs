using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Fix234 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_TopicHashtagMap_TopicId",
                table: "TopicHashtagMap",
                column: "TopicId");

            migrationBuilder.CreateIndex(
                name: "IX_CategoryHashtagMap_HashtagId",
                table: "CategoryHashtagMap",
                column: "HashtagId");

            migrationBuilder.AddForeignKey(
                name: "FK_CategoryHashtagMap_Hashtag_HashtagId",
                table: "CategoryHashtagMap",
                column: "HashtagId",
                principalTable: "Hashtag",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TopicHashtagMap_Topic_TopicId",
                table: "TopicHashtagMap",
                column: "TopicId",
                principalTable: "Topic",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CategoryHashtagMap_Hashtag_HashtagId",
                table: "CategoryHashtagMap");

            migrationBuilder.DropForeignKey(
                name: "FK_TopicHashtagMap_Topic_TopicId",
                table: "TopicHashtagMap");

            migrationBuilder.DropIndex(
                name: "IX_TopicHashtagMap_TopicId",
                table: "TopicHashtagMap");

            migrationBuilder.DropIndex(
                name: "IX_CategoryHashtagMap_HashtagId",
                table: "CategoryHashtagMap");
        }
    }
}
