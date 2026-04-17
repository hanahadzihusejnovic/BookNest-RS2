using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Interfaces
{
    public interface IImageService
    {
        Task<string> UploadImageAsync(Stream imageStream, string fileName, string containerName);
        Task<bool> DeleteImageAsync(string imageUrl, string containerName);
    }
}
