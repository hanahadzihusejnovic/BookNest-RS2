using System.ComponentModel.DataAnnotations;

namespace BookNest.Model.Requests
{
    public class PaymentMethodUpdateRequest
    {
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
    }
}
