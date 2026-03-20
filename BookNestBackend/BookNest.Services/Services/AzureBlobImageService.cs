using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using BookNest.Services.Interfaces;
using Microsoft.Extensions.Configuration;

namespace BookNest.Infrastructure.Services
{
    public class AzureBlobImageService : IImageService
    {
        private readonly BlobServiceClient _blobServiceClient;
        private readonly string _containerName = "book-covers";

        public AzureBlobImageService(IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("AzureStorageConnectionString");
            _blobServiceClient = new BlobServiceClient(connectionString);
        }

        public async Task<string> UploadImageAsync(Stream imageStream, string fileName)
        {
            var uniqueFileName = $"{Guid.NewGuid()}-{fileName}";

            var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            var blobClient = containerClient.GetBlobClient(uniqueFileName);

            await blobClient.UploadAsync(imageStream, new BlobHttpHeaders
            {
                ContentType = GetContentType(fileName)
            });

            return blobClient.Uri.ToString();
        }

        public async Task<bool> DeleteImageAsync(string imageUrl)
        {
            try
            {
                var uri = new Uri(imageUrl);
                var fileName = Path.GetFileName(uri.LocalPath);

                var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
                var blobClient = containerClient.GetBlobClient(fileName);

                await blobClient.DeleteIfExistsAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        private string GetContentType(string fileName)
        {
            var extension = Path.GetExtension(fileName).ToLowerInvariant();
            return extension switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".webp" => "image/webp",
                _ => "application/octet-stream"
            };
        }
    }
}