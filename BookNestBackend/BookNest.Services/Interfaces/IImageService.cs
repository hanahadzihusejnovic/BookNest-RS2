namespace BookNest.Services.Interfaces
{
    public interface IImageService
    {
        Task<string> UploadImageAsync(Stream imageStream, string fileName, string containerName);
        Task<bool> DeleteImageAsync(string imageUrl, string containerName);
    }
}
