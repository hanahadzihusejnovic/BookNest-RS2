using BookNest.Model.Exceptions;

namespace BookNest.API.Helpers
{
    public static class ImageValidationHelper
    {
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

        private static readonly Dictionary<string, byte[]> MagicBytes = new()
        {
            { ".jpg",  new byte[] { 0xFF, 0xD8, 0xFF } },
            { ".jpeg", new byte[] { 0xFF, 0xD8, 0xFF } },
            { ".png",  new byte[] { 0x89, 0x50, 0x4E, 0x47 } },
            { ".gif",  new byte[] { 0x47, 0x49, 0x46 } },
            { ".webp", new byte[] { 0x52, 0x49, 0x46, 0x46 } }
        };

        public static async Task ValidateImageAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new BusinessException("No image provided.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!AllowedExtensions.Contains(extension))
                throw new BusinessException("Only image files are allowed (.jpg, .jpeg, .png, .gif, .webp).");

            if (!MagicBytes.TryGetValue(extension, out var expectedBytes))
                throw new BusinessException("Unsupported image format.");

            var buffer = new byte[expectedBytes.Length];
            using var stream = file.OpenReadStream();
            await stream.ReadAsync(buffer, 0, buffer.Length);

            if (!buffer.Take(expectedBytes.Length).SequenceEqual(expectedBytes))
                throw new BusinessException("File content does not match the declared image format.");
        }
    }
}