using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BookNest.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusChangedByUserId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "StatusChangedByUserId",
                table: "Orders",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StatusChangedByUserId",
                table: "EventReservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_StatusChangedByUserId",
                table: "Orders",
                column: "StatusChangedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_EventReservations_StatusChangedByUserId",
                table: "EventReservations",
                column: "StatusChangedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_EventReservations_Users_StatusChangedByUserId",
                table: "EventReservations",
                column: "StatusChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_StatusChangedByUserId",
                table: "Orders",
                column: "StatusChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_EventReservations_Users_StatusChangedByUserId",
                table: "EventReservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_EventReservations_StatusChangedByUserId",
                table: "EventReservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedByUserId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "StatusChangedByUserId",
                table: "EventReservations");
        }
    }
}
