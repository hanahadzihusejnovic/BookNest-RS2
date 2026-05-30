using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BookNest.Services.Migrations
{
    /// <inheritdoc />
    public partial class FicObsoleteStatusValues : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("UPDATE Orders SET Status = 'Pending' WHERE Status = 'Processing'");
            migrationBuilder.Sql("UPDATE EventReservations SET ReservationStatus = 'Confirmed' WHERE ReservationStatus = 'Attended'");
        }


        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
