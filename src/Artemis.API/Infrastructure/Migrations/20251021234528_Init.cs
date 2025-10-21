using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Artemis.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Init : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateSequence(
                name: "Category_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "CategoryHashtagMap_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Comment_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Hashtag_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Mention_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "MentionPartyMap_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Message_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Organization_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Party_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Person_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Room_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "RoomHashtagMap_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Subscribe_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "Topic_hilo",
                incrementBy: 10);

            migrationBuilder.CreateSequence(
                name: "TopicHashtagMap_hilo",
                incrementBy: 10);

            migrationBuilder.CreateTable(
                name: "Category",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Category", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Hashtag",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    HashtagName = table.Column<string>(type: "text", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Hashtag", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Party",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    PartyName = table.Column<string>(type: "text", nullable: false),
                    PartyType = table.Column<int>(type: "integer", nullable: false),
                    IsBanned = table.Column<bool>(type: "boolean", nullable: false),
                    DeviceId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Party", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CategoryHashtagMap",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    HashtagId = table.Column<int>(type: "integer", nullable: false),
                    CategoryId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CategoryHashtagMap", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CategoryHashtagMap_Category_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "Category",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TopicHashtagMap",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    TopicId = table.Column<int>(type: "integer", nullable: false),
                    HashtagId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TopicHashtagMap", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TopicHashtagMap_Hashtag_HashtagId",
                        column: x => x.HashtagId,
                        principalTable: "Hashtag",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Organization",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Organization", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Organization_Party_Id",
                        column: x => x.Id,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Person",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Person", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Person_Party_Id",
                        column: x => x.Id,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Room",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    TopicId = table.Column<int>(type: "integer", nullable: true),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    CategoryId = table.Column<int>(type: "integer", nullable: true),
                    Title = table.Column<string>(type: "text", nullable: false),
                    LocationX = table.Column<double>(type: "double precision", nullable: false),
                    LocationY = table.Column<double>(type: "double precision", nullable: false),
                    Type = table.Column<double>(type: "double precision", nullable: false),
                    LifeCycle = table.Column<double>(type: "double precision", nullable: false),
                    ChannelId = table.Column<double>(type: "double precision", nullable: false),
                    ReferenceId = table.Column<string>(type: "text", nullable: false),
                    Upvote = table.Column<int>(type: "integer", nullable: false),
                    Downvote = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Room", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Room_Category_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "Category",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Room_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Subscribe",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    CreatedPartyId = table.Column<int>(type: "integer", nullable: false),
                    SubscriberPartyId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Subscribe", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Subscribe_Party_CreatedPartyId",
                        column: x => x.CreatedPartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Subscribe_Party_SubscriberPartyId",
                        column: x => x.SubscriberPartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Topic",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    LocationX = table.Column<double>(type: "double precision", nullable: false),
                    LocationY = table.Column<double>(type: "double precision", nullable: false),
                    CategoryId = table.Column<int>(type: "integer", nullable: false),
                    MentionId = table.Column<int>(type: "integer", nullable: true),
                    Upvote = table.Column<int>(type: "integer", nullable: false),
                    Downvote = table.Column<int>(type: "integer", nullable: false),
                    LastUpdateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Topic", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Topic_Category_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "Category",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Topic_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Message",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    RoomId = table.Column<int>(type: "integer", nullable: false),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    Upvote = table.Column<int>(type: "integer", nullable: false),
                    Downvote = table.Column<int>(type: "integer", nullable: false),
                    LastUpdateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Message", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Message_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Message_Room_RoomId",
                        column: x => x.RoomId,
                        principalTable: "Room",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RoomHashtagMap",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    RoomId = table.Column<int>(type: "integer", nullable: false),
                    HashtagId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoomHashtagMap", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RoomHashtagMap_Hashtag_HashtagId",
                        column: x => x.HashtagId,
                        principalTable: "Hashtag",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RoomHashtagMap_Room_RoomId",
                        column: x => x.RoomId,
                        principalTable: "Room",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Comment",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    TopicId = table.Column<int>(type: "integer", nullable: false),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    Upvote = table.Column<int>(type: "integer", nullable: false),
                    Downvote = table.Column<int>(type: "integer", nullable: false),
                    LastUpdateDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Comment", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Comment_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Comment_Topic_TopicId",
                        column: x => x.TopicId,
                        principalTable: "Topic",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Mention",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    RoomId = table.Column<int>(type: "integer", nullable: true),
                    MessageId = table.Column<int>(type: "integer", nullable: true),
                    CommentId = table.Column<int>(type: "integer", nullable: true),
                    TopicId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Mention", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Mention_Comment_CommentId",
                        column: x => x.CommentId,
                        principalTable: "Comment",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Mention_Message_MessageId",
                        column: x => x.MessageId,
                        principalTable: "Message",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Mention_Room_RoomId",
                        column: x => x.RoomId,
                        principalTable: "Room",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Mention_Topic_TopicId",
                        column: x => x.TopicId,
                        principalTable: "Topic",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MentionPartyMap",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false),
                    MentionId = table.Column<int>(type: "integer", nullable: false),
                    PartyId = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MentionPartyMap", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MentionPartyMap_Mention_MentionId",
                        column: x => x.MentionId,
                        principalTable: "Mention",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MentionPartyMap_Party_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Party",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CategoryHashtagMap_CategoryId",
                table: "CategoryHashtagMap",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Comment_PartyId",
                table: "Comment",
                column: "PartyId");

            migrationBuilder.CreateIndex(
                name: "IX_Comment_TopicId",
                table: "Comment",
                column: "TopicId");

            migrationBuilder.CreateIndex(
                name: "IX_Mention_CommentId",
                table: "Mention",
                column: "CommentId");

            migrationBuilder.CreateIndex(
                name: "IX_Mention_MessageId",
                table: "Mention",
                column: "MessageId");

            migrationBuilder.CreateIndex(
                name: "IX_Mention_RoomId",
                table: "Mention",
                column: "RoomId");

            migrationBuilder.CreateIndex(
                name: "IX_Mention_TopicId",
                table: "Mention",
                column: "TopicId");

            migrationBuilder.CreateIndex(
                name: "IX_MentionPartyMap_MentionId",
                table: "MentionPartyMap",
                column: "MentionId");

            migrationBuilder.CreateIndex(
                name: "IX_MentionPartyMap_PartyId",
                table: "MentionPartyMap",
                column: "PartyId");

            migrationBuilder.CreateIndex(
                name: "IX_Message_PartyId",
                table: "Message",
                column: "PartyId");

            migrationBuilder.CreateIndex(
                name: "IX_Message_RoomId",
                table: "Message",
                column: "RoomId");

            migrationBuilder.CreateIndex(
                name: "IX_Room_CategoryId",
                table: "Room",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Room_PartyId",
                table: "Room",
                column: "PartyId");

            migrationBuilder.CreateIndex(
                name: "IX_RoomHashtagMap_HashtagId",
                table: "RoomHashtagMap",
                column: "HashtagId");

            migrationBuilder.CreateIndex(
                name: "IX_RoomHashtagMap_RoomId",
                table: "RoomHashtagMap",
                column: "RoomId");

            migrationBuilder.CreateIndex(
                name: "IX_Subscribe_CreatedPartyId",
                table: "Subscribe",
                column: "CreatedPartyId");

            migrationBuilder.CreateIndex(
                name: "IX_Subscribe_SubscriberPartyId",
                table: "Subscribe",
                column: "SubscriberPartyId");

            migrationBuilder.CreateIndex(
                name: "IX_Topic_CategoryId",
                table: "Topic",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Topic_PartyId",
                table: "Topic",
                column: "PartyId");

            migrationBuilder.CreateIndex(
                name: "IX_TopicHashtagMap_HashtagId",
                table: "TopicHashtagMap",
                column: "HashtagId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CategoryHashtagMap");

            migrationBuilder.DropTable(
                name: "MentionPartyMap");

            migrationBuilder.DropTable(
                name: "Organization");

            migrationBuilder.DropTable(
                name: "Person");

            migrationBuilder.DropTable(
                name: "RoomHashtagMap");

            migrationBuilder.DropTable(
                name: "Subscribe");

            migrationBuilder.DropTable(
                name: "TopicHashtagMap");

            migrationBuilder.DropTable(
                name: "Mention");

            migrationBuilder.DropTable(
                name: "Hashtag");

            migrationBuilder.DropTable(
                name: "Comment");

            migrationBuilder.DropTable(
                name: "Message");

            migrationBuilder.DropTable(
                name: "Topic");

            migrationBuilder.DropTable(
                name: "Room");

            migrationBuilder.DropTable(
                name: "Category");

            migrationBuilder.DropTable(
                name: "Party");

            migrationBuilder.DropSequence(
                name: "Category_hilo");

            migrationBuilder.DropSequence(
                name: "CategoryHashtagMap_hilo");

            migrationBuilder.DropSequence(
                name: "Comment_hilo");

            migrationBuilder.DropSequence(
                name: "Hashtag_hilo");

            migrationBuilder.DropSequence(
                name: "Mention_hilo");

            migrationBuilder.DropSequence(
                name: "MentionPartyMap_hilo");

            migrationBuilder.DropSequence(
                name: "Message_hilo");

            migrationBuilder.DropSequence(
                name: "Organization_hilo");

            migrationBuilder.DropSequence(
                name: "Party_hilo");

            migrationBuilder.DropSequence(
                name: "Person_hilo");

            migrationBuilder.DropSequence(
                name: "Room_hilo");

            migrationBuilder.DropSequence(
                name: "RoomHashtagMap_hilo");

            migrationBuilder.DropSequence(
                name: "Subscribe_hilo");

            migrationBuilder.DropSequence(
                name: "Topic_hilo");

            migrationBuilder.DropSequence(
                name: "TopicHashtagMap_hilo");
        }
    }
}
