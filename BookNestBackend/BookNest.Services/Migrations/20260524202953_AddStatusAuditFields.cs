using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BookNest.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddStatusAuditFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "Orders",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StatusChangedAt",
                table: "Orders",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CancellationReason",
                table: "EventReservations",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StatusChangedAt",
                table: "EventReservations",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "StatusChangedAt",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "CancellationReason",
                table: "EventReservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedAt",
                table: "EventReservations");
        }
    }
}
