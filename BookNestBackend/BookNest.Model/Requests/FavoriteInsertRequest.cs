using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class FavoriteInsertRequest
    {
        [Required]
        public int BookId { get; set; }
    }
}
